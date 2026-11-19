import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .routers import admin, auth, hr, work

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("yash")

app = FastAPI(
    title="Yash Power Tech ERP API",
    version="0.1.0 (Phase 1 — Core ERP)",
    description="Authentication, roles & permissions, employees & HR, attendance, leave, tasks, documents, audit.",
    docs_url="/api/docs",
    openapi_url="/api/openapi.json",
)

for r in (auth.router, admin.router, hr.router, work.router):
    app.include_router(r)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response


@app.exception_handler(Exception)
async def unhandled(request: Request, exc: Exception):
    log.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


@app.get("/api/health")
def health():
    return {"status": "ok"}
