// Smoke de disponibilidade: verifica que a aplicação responde e está saudável.
// Sem metas de latência: o PRD só admite metas absolutas definidas por protocolo reproduzível.
// Execução: bash scripts/performance/smoke.sh (BASE_URL e DURATION opcionais).
import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export const options = {
  vus: 1,
  duration: __ENV.DURATION || '10s',
  thresholds: {
    http_req_failed: ['rate==0'],
    checks: ['rate==1'],
  },
};

export default function () {
  const response = http.get(`${BASE_URL}/actuator/health`);
  check(response, {
    'status 200': (r) => r.status === 200,
    'health UP': (r) => r.json('status') === 'UP',
  });
}
