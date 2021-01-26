#!/bin/sh
#
# Format the LibreOffice write document into a print-ready PDF with two pages on
# each "side", for a total of 4 booklet pages per two-sided page when printed.
#

# Export the file to PDF
"`dirname "$0"`/make_pdf.sh"

BASE_FILE="skunk_manual"
PDF_FILE="$BASE_FILE.pdf"
RIGHT_PAGES_FILE="$BASE_FILE-cropped_right.pdf"
LEFT_PAGES_FILE="$BASE_FILE-cropped_left.pdf"

# Build page lists
RIGHT_PAGES=""
LEFT_PAGES=""
NUM_PAGES=`pdfinfo "${PDF_FILE}" | grep Pages | sed -e 's/[^0-9]*//'`

PAGE=1
COMMA=""
while [ $PAGE -lt $NUM_PAGES ]; do
	RIGHT_PAGES="$RIGHT_PAGES$COMMA$PAGE"
	COMMA=","
	PAGE=`expr $PAGE + 2`
done
if [ $PAGE -le $NUM_PAGES ]; then
	RIGHT_PAGES="$RIGHT_PAGES,$PAGE"
fi

PAGE=2
COMMA=""
while [ $PAGE -lt $NUM_PAGES ]; do
	LEFT_PAGES="$LEFT_PAGES$COMMA$PAGE"
	COMMA=","
	PAGE=`expr $PAGE + 2`
done
if [ $PAGE -le $NUM_PAGES ]; then
	LEFT_PAGES="$LEFT_PAGES$COMMA$PAGE"
fi

echo "Left pages: $LEFT_PAGES"
echo "Right pages: $RIGHT_PAGES"

# Trim off the left border on right pages, the right border on left pages
pdfjam --keepinfo --papersize '{4.75in,7in}' --trim "0.25in 0in 0in 0in" --clip true --outfile "$RIGHT_PAGES_FILE" "$PDF_FILE" "$RIGHT_PAGES"
pdfjam --keepinfo --papersize '{4.75in,7in}' --trim "0in 0in 0.25in 0in" --clip true --outfile "$LEFT_PAGES_FILE" "$PDF_FILE" "$LEFT_PAGES"

# Separate the cropped files into individual pages:
pdfseparate "$RIGHT_PAGES_FILE" "$BASE_FILE-%04d-0.pdf"
pdfseparate "$LEFT_PAGES_FILE" "$BASE_FILE-%04d-1.pdf"

# Reformat the resulting PDF into a booklet by joining appropriate pages
pdfbook --papersize '{7in,9.5in}' --outfile "$BASE_FILE-book.pdf" "$BASE_FILE"-*-*.pdf
rm "$BASE_FILE"-*-* "$RIGHT_PAGES_FILE" "$LEFT_PAGES_FILE"
