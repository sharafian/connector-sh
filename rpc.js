const Koa = require('koa')

const app = new Koa()
const router = require('koa-router')()
const parser = require('koa-bodyparser')()

router.post('/rpc/bob', async (ctx) => {
  console.log('POST bob', ctx.request.body)
  ctx.statusCode = 204
  ctx.body = "Success\n"
})

router.post('/rpc/alice', async (ctx) => {
  console.log('POST alice', ctx.request.body)
  ctx.statusCode = 204
  ctx.body = "Success\n"
})

app
  .use(parser)
  .use(router.routes())
  .use(router.allowedMethods())
  .listen(8090)

console.log('LISTEN 8090')
