/**
 * @param {string} USERNAME User name to access the page
 * @param {string} PASSWORD Password to access the page
 * @param {string} REALM A name of an area (a page or a group of pages) to protect.
 * Some browsers may show "Enter user name and password to access REALM"
 *
 * Sourced from: https://www.maxivanov.io/how-to-password-protect-your-website-with-cloudflare-workers/
 */
const USERNAME = "${username}";
const PASSWORD = "${password}";
const REALM = "Secure Area";

addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const authorization = request.headers.get("authorization");
  if (!request.headers.has("authorization")) {
    return getUnauthorizedResponse(
      "Provide User Name and Password to access this page.",
    );
  }
  const credentials = parseCredentials(authorization);
  if (credentials[0] !== USERNAME || credentials[1] !== PASSWORD) {
    return getUnauthorizedResponse(
      "The User Name and Password combination you have entered is invalid.",
    );
  }
  return await fetch(request);
}

function parseCredentials(authorization) {
  const parts = authorization.split(" ");
  const plainAuth = atob(parts[1]);
  const credentials = plainAuth.split(":");
  return credentials;
}

function getUnauthorizedResponse(message) {
  let response = new Response(message, {
    status: 401,
  });
  response.headers.set("WWW-Authenticate", `Basic realm=Secure Area`);
  return response;
}
