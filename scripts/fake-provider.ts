// Fake OpenAI-compatible provider for the Peak Switcher lab.
// It answers with the model name so the transcript proves which model served the turn.
//
// Failure injection:
//   PEAK_FAIL_MODEL=one PEAK_FAIL_STATUS=402 PEAK_FAIL_TIMES=1 bun scripts/fake-provider.ts
//
// The first `PEAK_FAIL_TIMES` requests to that model return the chosen status with an
// OpenRouter-shaped error body, which is what the cascade classifies.

const port = Number(process.env.PEAK_FAKE_PORT ?? 8787)
const failModel = process.env.PEAK_FAIL_MODEL
const failStatus = Number(process.env.PEAK_FAIL_STATUS ?? 402)
const failTimes = Number(process.env.PEAK_FAIL_TIMES ?? 1)
const models = ["one", "two", "three", "muse"]

const seen = new Map<string, number>()

function errorBody(status: number, model: string) {
  if (status === 429) {
    return {
      error: {
        code: 429,
        message: `Rate limit exceeded for ${model}`,
        metadata: { error_type: "rate_limit_exceeded" },
      },
    }
  }
  if (status === 404) {
    return { error: { code: 404, message: `Model not found: ${model}` } }
  }
  return {
    error: {
      code: status,
      message: `Insufficient credits for ${model}`,
      metadata: { limit_source: "openrouter_credits", remedy_hint: "Add credits." },
    },
  }
}

function completion(model: string) {
  return {
    id: `fake-${model}`,
    object: "chat.completion",
    created: Math.floor(Date.now() / 1000),
    model,
    choices: [
      {
        index: 0,
        message: { role: "assistant", content: `ok from ${model}` },
        finish_reason: "stop",
      },
    ],
    usage: { prompt_tokens: 1, completion_tokens: 3, total_tokens: 4 },
  }
}

function chunk(model: string, delta: Record<string, unknown>, finish: string | null) {
  return {
    id: `fake-${model}`,
    object: "chat.completion.chunk",
    created: Math.floor(Date.now() / 1000),
    model,
    choices: [{ index: 0, delta, finish_reason: finish }],
  }
}

const server = Bun.serve({
  port,
  async fetch(req) {
    const url = new URL(req.url)

    if (url.pathname === "/v1/models") {
      return Response.json({
        object: "list",
        data: models.map((id) => ({ id, object: "model", owned_by: "fake" })),
      })
    }
    if (url.pathname !== "/v1/chat/completions") return new Response("not found", { status: 404 })

    const body = await req.json()
    const model = String(body.model ?? "unknown")
    const count = (seen.get(model) ?? 0) + 1
    seen.set(model, count)

    const shouldFail = failModel === model && count <= failTimes
    console.log(
      JSON.stringify({
        event: "request",
        model,
        stream: body.stream !== false,
        attempt: count,
        status: shouldFail ? failStatus : 200,
      }),
    )

    if (shouldFail) {
      return Response.json(errorBody(failStatus, model), { status: failStatus })
    }

    if (body.stream === false) return Response.json(completion(model))

    const encoder = new TextEncoder()
    const stream = new ReadableStream({
      start(controller) {
        const send = (payload: unknown) =>
          controller.enqueue(encoder.encode(`data: ${JSON.stringify(payload)}\n\n`))
        send(chunk(model, { role: "assistant", content: `ok from ${model}` }, null))
        send({
          ...chunk(model, {}, "stop"),
          usage: { prompt_tokens: 1, completion_tokens: 3, total_tokens: 4 },
        })
        controller.enqueue(encoder.encode("data: [DONE]\n\n"))
        controller.close()
      },
    })
    return new Response(stream, {
      headers: { "content-type": "text/event-stream", "cache-control": "no-cache" },
    })
  },
})

console.log(JSON.stringify({ event: "listening", url: server.url.toString(), failModel, failStatus, failTimes }))
