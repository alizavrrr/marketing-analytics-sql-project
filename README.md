
# Marketing Channels Analysis (SQL)

## 🧩 About the project
In this project, I analyzed marketing channels of an e-commerce business to understand how efficiently customers are acquired and how quickly they become profitable.

---

## 📈 What I did
I calculated key product and marketing metrics:

- LTV (average revenue per customer)  
- CAC (customer acquisition cost)  
- LTV/CAC ratio  
- Payback period (in months)  
- Revenue in the first 3 months  

---

## 🗂 Data
The analysis is based on 4 tables:

- `orders`  
- `order_items`  
- `customers`  
- `marketing_daily`  

---

## 📊 Results

| Channel  | LTV | CAC | LTV/CAC | Payback | Revenue 3M |
|----------|-----|-----|---------|--------|-----------|
| Ads      | 3776 | 2093 | 1.80 | 4.9 | 1295 |
| Social   | 3235 | 1729 | 1.87 | 5.0 | 1222 |
| Referral | 3339 | 325  | 10.27 | 0.4 | 1534 |
| Organic  | 3553 | 0    | —    | 0.0 | 1281 |

---

## 💡 Key insights
- Referral is the most efficient channel — customers pay back almost immediately  
- Organic traffic is free but cannot be scaled  
- Paid channels (ads and social) are scalable but require optimization  

---

## 🧠 Conclusion
The business should not rely on a single channel.  
The best strategy is to combine paid acquisition with referral growth and improve early monetization.

---

## 🛠 Tools
- SQL (DuckDB)  
- Aggregations  
- Window functions  
