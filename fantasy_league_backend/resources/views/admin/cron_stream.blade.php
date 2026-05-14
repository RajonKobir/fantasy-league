<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Updating Fantasy Teams Points</title>
  <style>
    body { font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; padding: 20px; }
    .bar { height: 18px; background: #e5e7eb; border-radius: 6px; overflow: hidden; }
    .bar > .fill { height: 100%; background: #3b82f6; width: 0%; transition: width 0.3s; }
  </style>
</head>
<body>
  <h1>Updating Fantasy Teams Points</h1>
  <p id="status">Connecting...</p>
  <div class="bar mt-4 mb-2"><div class="fill" id="progressFill"></div></div>
  <p><strong id="counter">0</strong> teams updated</p>
  <pre id="log" style="background:#f8fafc;padding:10px;border-radius:6px;max-height:420px;overflow:auto"></pre>

  <script>
    (function(){
      const tournamentId = new URLSearchParams(location.search).get('tournament_id');
      const streamUrl = '/admin/cron/update-fantasy-team-points/stream' + (tournamentId ? ('?tournament_id=' + encodeURIComponent(tournamentId)) : '');
      const statusEl = document.getElementById('status');
      const counterEl = document.getElementById('counter');
      const logEl = document.getElementById('log');
      const fillEl = document.getElementById('progressFill');

      const es = new EventSource(streamUrl);
      let total = 0;
      let updated = 0;

      es.onmessage = function(e) {
        try {
          const data = JSON.parse(e.data);
          if (data.status === 'start') {
            total = data.total || 0;
            statusEl.textContent = `Started - ${total} teams to process`;
            logEl.textContent += `Started processing ${total} teams\n`;
          } else if (data.status === 'progress') {
            updated = data.updated || updated;
            statusEl.textContent = `Processing - ${updated} / ${data.total}`;
            counterEl.textContent = updated;
            const pct = data.total ? Math.round((updated/data.total)*100) : 0;
            fillEl.style.width = pct + '%';
          } else if (data.status === 'error') {
            logEl.textContent += `Error: ${data.message}\n`;
          } else if (data.status === 'done') {
            updated = data.updated || updated;
            statusEl.textContent = `Done - ${updated} updated, ${data.errors || 0} errors`;
            counterEl.textContent = updated;
            const pct = data.total ? Math.round((updated/data.total)*100) : 100;
            fillEl.style.width = pct + '%';
            logEl.textContent += `Done. ${updated} updated, ${data.errors || 0} errors\n`;
            es.close();
          }
        } catch (err) {
          logEl.textContent += `Received malformed message: ${e.data}\n`;
        }
      };

      es.onerror = function(err) {
        statusEl.textContent = 'Connection error, check server logs';
        logEl.textContent += 'SSE error or connection closed by server\n';
        es.close();
      };
    })();
  </script>
</body>
</html>