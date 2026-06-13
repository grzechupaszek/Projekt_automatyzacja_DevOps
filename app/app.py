from flask import Flask, jsonify

app = Flask(__name__)

# Autor: Grzegorz Paszek, nr albumu 422374
# wersja 1.0 — pierwszy automatyczny deployment przez CI/CD

@app.route("/")
def index():
    return jsonify(
        message="DevOps 2026 — GitOps demo",
        author="Grzegorz Paszek",
        album="422374",
        status="ok",
    )


@app.route("/health")
def health():
    return jsonify(status="healthy"), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
