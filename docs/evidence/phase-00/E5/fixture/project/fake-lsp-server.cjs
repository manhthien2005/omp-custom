'use strict';

let buffer = Buffer.alloc(0);

function send(message) {
  const body = Buffer.from(JSON.stringify(message), 'utf8');
  process.stdout.write(`Content-Length: ${body.length}\r\n\r\n`);
  process.stdout.write(body);
}

function respond(message) {
  if (message.id === undefined || message.id === null) {
    if (message.method === 'exit') process.exit(0);
    return;
  }

  if (message.method === 'initialize') {
    send({
      jsonrpc: '2.0',
      id: message.id,
      result: {
        capabilities: {
          textDocumentSync: { openClose: true, change: 1 },
          referencesProvider: true
        },
        serverInfo: { name: 'phase00-fake-lsp', version: '1.0.0' }
      }
    });
    return;
  }

  if (message.method === 'textDocument/references') {
    const uri = message.params && message.params.textDocument
      ? message.params.textDocument.uri
      : 'file:///probe.ts';
    send({
      jsonrpc: '2.0',
      id: message.id,
      result: [{
        uri,
        range: {
          start: { line: 0, character: 16 },
          end: { line: 0, character: 21 }
        }
      }]
    });
    return;
  }

  if (message.method === 'shutdown') {
    send({ jsonrpc: '2.0', id: message.id, result: null });
    return;
  }

  send({ jsonrpc: '2.0', id: message.id, result: null });
}

process.stdin.on('data', chunk => {
  buffer = Buffer.concat([buffer, chunk]);
  for (;;) {
    const headerEnd = buffer.indexOf('\r\n\r\n');
    if (headerEnd < 0) return;
    const header = buffer.subarray(0, headerEnd).toString('ascii');
    const match = /(?:^|\r\n)Content-Length:\s*(\d+)/i.exec(header);
    if (!match) process.exit(2);
    const length = Number(match[1]);
    const frameEnd = headerEnd + 4 + length;
    if (buffer.length < frameEnd) return;
    const body = buffer.subarray(headerEnd + 4, frameEnd).toString('utf8');
    buffer = buffer.subarray(frameEnd);
    try {
      respond(JSON.parse(body));
    } catch {
      process.exit(3);
    }
  }
});

process.stdin.on('end', () => process.exit(0));
