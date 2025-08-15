import net from 'node:net'

export default async function pusu() {
  return new Promise((res) => {
    const client = new net.Socket()

    const HOST = '127.0.0.1'
    const PORT = 1234

    client.connect(PORT, HOST, () => {
      res(client)
    })
  })
}
