// Viewer-request function (rendered by tf/cloudfront.tf).
// Rejects known AI crawlers and AI search/assistant agents; robots.txt stays readable
// so they can see the opt-out.
var AI_AGENTS = /${ai_agents_pattern}/i;

function handler(event) {
    var request = event.request;
    var userAgent = request.headers["user-agent"] ? request.headers["user-agent"].value : "";

    if (request.uri !== "/robots.txt" && AI_AGENTS.test(userAgent)) {
        return { statusCode: 403, statusDescription: "Forbidden" };
    }
%{ if rewrite_index ~}

    // Serve index.html for directory URLs (formerly the shared default-root-object function).
    if (request.uri.endsWith("/")) {
        request.uri += "index.html";
    } else if (!request.uri.includes(".")) {
        request.uri += "/index.html";
    }
%{ endif ~}

    return request;
}
