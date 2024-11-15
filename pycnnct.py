import os
import http.server
import html
import logging

logging.basicConfig(level=logging.DEBUG)


def book(*args):
    logging.debug(" ".join(str(arg) for arg in args))


class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length)
        boundary = self.headers["Content-Type"].split("=")[1].encode()
        parts = post_data.split(boundary)
        # book('libq boundary', boundary, parts)

        for part in parts:
            if b'filename="' in part:
                filename_start = part.find(b'filename="') + len(b'filename="')
                filename_end = part.find(b'"', filename_start)
                filename = html.unescape(part[filename_start:filename_end].decode())
                file_content_start = part.find(b"\r\n\r\n") + 4
                file_content_end = -4
                # book('libq file_content_bounds', file_content_start, file_content_end, part)
                file_content = part[file_content_start:file_content_end]
                filepath = os.path.join(os.getcwd(), filename)
                with open(filepath, "wb") as output_file:
                    output_file.write(file_content)
                    book("libq written", len(file_content), "to", filepath)

                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"File successfully uploaded")
                return

        self.send_response(400)
        self.end_headers()
        self.wfile.write(b"No file selected or bad request")

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(b"""
        <!doctype html>
        <html>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <head>
            <style>
                * {
                    background: black;
                    color: white;
                }
            </style>
            <title>Upload File</title>
        </head>
        <body>
            <h1>Upload File</h1>
            <p>it uploads as soon as you select a file</p>
            <p>do not leave the browser until it says upload is successful</p>
            <form method="post" enctype="multipart/form-data">
                <input type="file" name="file" required onchange="this.form.submit()">
            </form>
        </body>
        </html>
        """)


def run(
    server_class=http.server.HTTPServer,
    handler_class=CustomHTTPRequestHandler,
    port=8000,
):
    server_address = ("", port)
    httpd = server_class(server_address, handler_class)
    print(f"Server running on port {port}...")
    httpd.serve_forever()


if __name__ == "__main__":
    run()
