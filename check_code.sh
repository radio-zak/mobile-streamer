#!/bin/sh

# Wiadomość dla dewelopera
echo "Running code quality check: Formatting and analyzing..."

# 1. Uruchom formatowanie
dart format .

# 2. Uruchom analizę kodu (w tym linting)
dart analyze

# 3. Sprawdź, czy analiza zakończyła się sukcesem
if [ $? -eq 0 ]; then
  echo "---------------------------------"
  echo "Success! Code is clean."
  echo "---------------------------------"
else
  echo "---------------------------------"
  echo "Found issues. Please fix them."
  echo "---------------------------------"
fi
