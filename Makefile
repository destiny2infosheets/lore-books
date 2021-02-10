# DIM's API key. insanity_wolf.jpg: it's public anyways.
API_KEY := 5ec01caf6aee450d9dabe646294ffdc9

.PHONY: all
all: books
	# Start a new instance of make, so that generated JSON files are visible as
	# target dependencies.
	$(MAKE) epubs

tmp out:
	mkdir $@

tmp/manifest.json: | tmp
	path="$$(curl --silent --header 'X-API-Key: $(API_KEY)' https://www.bungie.net/Platform/Destiny2/Manifest/ \
	  | jq --raw-output .Response.jsonWorldContentPaths.en)"; \
	url="https://www.bungie.net$${path}"; \
	curl --silent --header 'X-API-Key: $(API_KEY)' --header 'Content-Type: application/json' "$${url}" | jq > $@

tmp/books.json: tmp/manifest.json extract_books.jq
	jq -f extract_books.jq tmp/manifest.json > $@

.PHONY: books
books: tmp/books.json
	jq '.[] | .hash' --raw-output $< | while read hash; do \
		jq ".[] | select(.hash == $${hash})" $< > tmp/book_$${hash}.json; \
	done

%.png: %.json
	curl --silent https://www.bungie.net$$(jq --raw-output '.cover' $<) > $@

%.txt: %.json format_book.jq
	jq --raw-output -f format_book.jq $< > $@

.PHONY: images texts epubs
images: $(patsubst %.json,%.png,$(wildcard tmp/book_*.json))
texts: $(patsubst %.json,%.txt,$(wildcard tmp/book_*.json))

epubs: images texts $(wildcard tmp/book_*.json) format_book.jq | out
	cd tmp && \
	for file in book_*.json; do \
		 pandoc $${file%.json}.txt -o "../out/$$(jq --raw-output '.title' $${file}).epub"; \
	done

clean:
	rm -r tmp out || true
