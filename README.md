CyberTrend-Radar Powered by Reddit
Übersicht

Dieses PowerShell-Skript sammelt und analysiert aktuelle Cybersecurity-Trends aus Reddit. Es hilft, wichtige Themen und Diskussionen aus relevanten Subreddits zu identifizieren und so auf dem neuesten Stand der Cybersecurity-Community zu bleiben.
Features

    Abrufen von Posts und Kommentaren aus ausgewählten Cybersecurity-Subreddits

    Extraktion und Analyse von Trendbegriffen

    Ausgabe der Ergebnisse als übersichtliche Textdateien oder CSV

    Einfache Anpassung der Subreddit-Liste und Filteroptionen

Voraussetzungen

    Windows PowerShell 5.1 oder höher (besser PowerShell 7+)

    Internetverbindung

    Reddit API-Zugang (optional, falls das Skript API-basiert arbeitet)

Installation

    Repository klonen oder ZIP herunterladen und entpacken:

git clone https://github.com/0x4D2/CyberTrend-Radar-Powered-by-Reddit.git
cd CyberTrend-Radar-Powered-by-Reddit

Skript ausführen:

    ./RedditTrendScanner.ps1

Nutzung

    Passe im Skript die Liste der Subreddits oder Suchbegriffe an.

    Starte das Skript in PowerShell.

    Die Ergebnisse werden im Ordner output gespeichert.

Anpassungen

    Subreddit-Liste: Direkt im Skript ändern (Variable $Subreddits)

    Zeitraum, Anzahl der Posts: Im Skript einstellbar

    Ausgabeformat: TXT oder CSV

Support und Mitwirkung

Wenn du Fehler findest oder das Skript verbessern möchtest, öffne gerne ein Issue oder sende einen Pull Request.
Lizenz

MIT License
