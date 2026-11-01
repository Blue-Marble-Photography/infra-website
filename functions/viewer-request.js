// Viewer-request function (rendered by tf/cloudfront.tf).
// Rejects known AI crawlers and AI search/assistant agents; robots.txt and the TDMRep
// file stay readable so they can see the opt-out.
var OPT_OUT_PATHS = { "/robots.txt": true, "/.well-known/tdmrep.json": true };
var AI_AGENTS = /${ai_agents_pattern}/i;

function handler(event) {
    var request = event.request;
    var userAgent = request.headers["user-agent"] ? request.headers["user-agent"].value : "";

    if (!OPT_OUT_PATHS[request.uri] && AI_AGENTS.test(userAgent)) {
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
