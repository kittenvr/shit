from datetime import datetime
import requests
import csv

def scrape_eldorado_offers(
    output_csv="osrs_accounts.csv",
    initial_page=1,
    page_size=24,
    search_query="Java"
):
    """
    Scrape Minecraft account listings from Eldorado.gg's flexibleOffers API
    and store them in a CSV file with additional fields:
    - URL
    - Title
    - Price (USD)
    - Seller Rating (rounded)
    - Description
    - Positive Count
    - Negative Count
    - Rating Count
    - Feedback Score (raw)
    """
    base_url = "https://www.eldorado.gg/api/flexibleOffers/"

    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        # CSV header:
        writer.writerow([
            "URL",
            "Title",
            "Description",
            "Price (USD)",
            "Seller Rating (rounded)",
            "Rating Count",
            "Positive Count",
            "Negative Count",
            "Feedback Score (raw)"
        ])

        page_index = initial_page
        total_pages = None

        while True:
            params = {
                "gameId": 61,                 # Minecraft
                "category": "Account",
                "usePerGameScore": "false",
                "searchQuery": search_query,
                "pageIndex": page_index,
                "pageSize": page_size,
                "offerSortingCriterion": "Price",
                "isAscending": "true"
            }
            resp = requests.get(base_url, params=params)
            if resp.status_code != 200:
                print(f"Request failed at page {page_index}, status code: {resp.status_code}")
                break

            data = resp.json()

            # Capture total_pages from the first response
            if total_pages is None:
                total_pages = data.get("totalPages", 1)

            results = data.get("results", [])
            if not results:
                print("No more results found. Exiting.")
                break

            for item in results:
                offer = item.get("offer", {})
                user_order_info = item.get("userOrderInfo", {})

                # Offer fields
                offer_id = offer.get("id", "")
                # game_alias = offer.get("gameSeoAlias", "osrs-accounts-for-sale")
                offer_title = offer.get("offerTitle", "").strip()
                # print(offer_title)
                offer_desc = offer.get("description", "")
                if offer_desc is not None:
                    offer_desc = offer_desc.strip()
                else:
                    offer_desc = ""

                # Price
                price_data = offer.get("pricePerUnitInUSD", {})
                price_amount = price_data.get("amount", None)

                # Seller info
                positive_count = user_order_info.get("positiveCount", 0)
                negative_count = user_order_info.get("negativeCount", 0)
                rating_count   = user_order_info.get("ratingCount", 0)
                feedback_score = user_order_info.get("feedbackScore", 0.0)  # raw

                # "Seller Rating" (rounded) - same as feedback_score, but we round
                seller_rating_rounded = round(feedback_score, 2)

                # Construct the offer URL
                if offer_id:
                    offer_url = f"https://www.eldorado.gg/minecraft-accounts/oa/{offer_id}"
                else:
                    offer_url = ""

                # Write row to CSV
                writer.writerow([
                    offer_url,
                    offer_title,
                    offer_desc,
                    price_amount,
                    seller_rating_rounded,
                    rating_count,
                    positive_count,
                    negative_count,
                    feedback_score,
                ])

            print(f"Page {page_index} scraped successfully.")

            page_index += 1

            # Stop if we've reached or exceeded total_pages
            if page_index > total_pages:
                break

    print(f"Scraping complete. Data saved to {output_csv}.")

if __name__ == "__main__":
    scrape_eldorado_offers(
        output_csv=f"minecraft_accounts_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.csv",
        initial_page=1,  # start scraping from page 1
        page_size=24     # how many offers per page
    )