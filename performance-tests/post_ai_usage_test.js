import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  duration: '5s',
  vus: 10,
  thresholds: {
    http_req_failed: ['rate<0.001'],
    http_req_duration: ['p(95)<500'],
  },
};

const BASE_URL = 'http://localhost:3000';
const USER_COUNT = 10;

export default function () {
  // Assign each virtual user a unique test account
  const userNumber = ((__VU - 1) % USER_COUNT) + 1;
  const email = `test${userNumber}@example.com`;
  const password = 'password123';

  // Step 1: Sign in user
  const loginPayload = JSON.stringify({
    user: {
      email: email,
      password: password,
    },
  });

  const loginParams = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const loginResponse = http.post(
    `${BASE_URL}/api/v1/login`,
    loginPayload,
    loginParams
  );

  check(loginResponse, {
    'login successful': (r) => r.status === 200,
  });

  if (loginResponse.status !== 200) {
    console.error(`Login failed for ${email}: ${loginResponse.status}`);
    return;
  }

  // Step 2: Extract bearer token from response headers
  const authHeader = loginResponse.headers['Authorization'] || loginResponse.headers['authorization'];
  const token = authHeader?.replace('Bearer ', '');

  if (!token) {
    console.error(`No JWT token received for ${email}`);
    return;
  }

  // Step 3: Request AI usage data
  const usageParams = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
  };

  const usageResponse = http.post(
    `${BASE_URL}/api/v1/ai/usage`,
    null,
    usageParams
  );

  check(usageResponse, {
    'usage request successful': (r) => r.status === 200,
  });

  // Step 4: Sign out user
  const logoutParams = {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  };

  const logoutResponse = http.del(
    `${BASE_URL}/api/v1/logout`,
    null,
    logoutParams
  );

  check(logoutResponse, {
    'logout successful': (r) => r.status === 200,
  });

  console.log(`Request for user ${email} was successful.`)

  sleep(1);
}