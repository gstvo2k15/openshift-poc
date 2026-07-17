package poc;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.InetAddress;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        String message = System.getenv()
                .getOrDefault("APP_MESSAGE", "Hello OpenShift POC");

        String podName = System.getenv()
                .getOrDefault("HOSTNAME", InetAddress.getLocalHost().getHostName());

        try (PrintWriter out = response.getWriter()) {
            out.println("""
                <!doctype html>
                <html lang="es">
                <head>
                    <meta charset="UTF-8">
                    <title>Hello OpenShift</title>
                    <style>
                        body {
                            font-family: sans-serif;
                            max-width: 900px;
                            margin: 4rem auto;
                            line-height: 1.5;
                        }
                        code {
                            background: #eeeeee;
                            padding: 0.2rem 0.4rem;
                        }
                    </style>
                </head>
                <body>
                    <h1>%s</h1>
                    <p>WAR built with Maven.</p>
                    <p>Server: Apache Tomcat 9.</p>
                    <p>Pod that responded: <code>%s</code></p>
                </body>
                </html>
                """.formatted(escapeHtml(message), escapeHtml(podName)));
        }
    }

    private static String escapeHtml(String value) {
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}