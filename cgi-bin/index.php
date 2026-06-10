#!/usr/bin/usr/env php-cgi
<?php
// Mandatory CGI Header
echo "Content-Type: text/html\r\n\r\n";

try {
    // Relative path to keep the database in your testing root folder
    $db = new PDO('sqlite:../database.sqlite');
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $db->exec("CREATE TABLE IF NOT EXISTS visits (id INTEGER PRIMARY KEY, ts TEXT)");

    $stmt = $db->prepare("INSERT INTO visits (ts) VALUES (:ts)");
    $stmt->execute([':ts' => date('Y-m-d H:i:s')]);

    $count = $db->query("SELECT COUNT(*) FROM visits")->fetchColumn();

    echo "<html><head><title>Workspace Hidden Service</title></head><body style='font-family:sans-serif;'>";
    echo "<h1>Hello from /workspaces/testing!</h1>";
    echo "<p>SQLite Visit Count: <strong>" . htmlspecialchars($count) . "</strong></p>";
    echo "</body></html>";

} catch (PDOException $e) {
    echo "Database error: " . htmlspecialchars($e->getMessage());
}
?>
