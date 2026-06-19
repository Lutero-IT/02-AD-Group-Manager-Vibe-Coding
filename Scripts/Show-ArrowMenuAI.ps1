function Show-ArrowMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$MenuOptions,

        [Parameter(Mandatory = $false)]
        [string]$CurrentGroup = 'None',

        [Parameter(Mandatory = $false)]
        [string]$Title = 'Menu'
    )

    # 1. Sprawdzenie, czy tablica opcji nie jest pusta
    if ($MenuOptions.Count -eq 0) {
        Write-Error "The menu options array cannot be empty."
        return -1
    }

    # 2. Inicjalizacja zmiennych sterujących nawigacją
    $selectedIndex = 0
    $running = $true
    $frameWidth = 41 # Stała szerokość ramki dopasowana do nagłówków

    # Ukrycie kursora w konsoli (dla lepszego efektu wizualnego TUI)
    $oldCursorVisible = $Host.UI.RawUI.CursorSize
    try {
        $Host.UI.RawUI.CursorSize = 0
    } catch {}

    # 3. Główna pętla renderowania interfejsu tekstowego (TUI)
    while ($running) {
        Clear-Host

        # --- Dynamiczne centrowanie Tytułu Menu ---
        # Obliczamy ile spacji potrzebujemy po bokach, aby wyśrodkować tytuł w ramce o szerokości 41 znaków
        $spacesNeeded = $frameWidth - $Title.Length
        if ($spacesNeeded -lt 0) { $spacesNeeded = 0 }
        $leftSpaces = [math]::Floor($spacesNeeded / 2)
        $rightSpaces = $spacesNeeded - $leftSpaces

        $paddedTitle = (" " * $leftSpaces) + $Title + (" " * $rightSpaces)

        # RENDEROWANIE NAGŁÓWKA I TYTUŁU
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host "$paddedTitle" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host "You are currently editing '$CurrentGroup' group" -ForegroundColor Yellow
        Write-Host "-----------------------------------------" -ForegroundColor Cyan
        Write-Host ""

        # Wyświetlanie opcji menu z wyróżnieniem zaznaczonego elementu
        for ($i = 0; $i -lt $MenuOptions.Count; $i++) {
            if ($i -eq $selectedIndex) {
                # Podświetlenie wybranej opcji: odwrócenie kolorów (czarny tekst na białym tle)
                Write-Host " > $($MenuOptions[$i]) " -ForegroundColor Black -BackgroundColor White
            } else {
                # Standardowa opcja
                Write-Host "   $($MenuOptions[$i])"
            }
        }

        # 4. Przechwytywanie klawiszy strzałek oraz klawisza Enter
        $keyInfo = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($keyInfo.VirtualKeyCode) {
            38 { # Up Arrow
                $selectedIndex--
                if ($selectedIndex -lt 0) {
                    $selectedIndex = $MenuOptions.Count - 1 # Przejście na koniec listy (loop)
                }
            }
            40 { # Down Arrow
                $selectedIndex++
                if ($selectedIndex -ge $MenuOptions.Count) {
                    $selectedIndex = 0 # Powrót na początek listy (loop)
                }
            }
            13 { # Enter Key
                $running = $false # Zatwierdzenie i wyjście z pętli
            }
        }
    }

    # Przywrócenie widoczności kursora przed wyjściem z funkcji
    try {
        $Host.UI.RawUI.CursorSize = $oldCursorVisible
    } catch {}

    # Czyszczenie ekranu po zakończeniu menu
    Clear-Host

    # 5. Zwrócenie indeksu typu Integer wybranej opcji (0-based indeks)
    return $selectedIndex
}