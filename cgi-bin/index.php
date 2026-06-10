#!/usr/bin/env php-cgi
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

    echo "<html><head><title>Workspace Hidden Service</title></head><body style='font-family:sans-serif; background:#f4f4f4; padding:40px;'>";
    echo "<div style='background:white; padding:20px; border-radius:8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width:500px; margin:0 auto;'>";
    echo "<h1>Hello from /workspaces/testing!</h1>";
    echo "<p>Your clean URL routing layer is active.</p>";
    echo "<p>SQLite Visit Count: <strong style='color:#007bff;'>" . htmlspecialchars($count) . "</strong></p>";
    echo "</div></body></html>";

} catch (PDOException $e) {
    echo "Database error: " . htmlspecialchars($e->getMessage());
}
?>
