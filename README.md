# Turbo Firewall Installation

To install Turbo Firewall on your server, run the following command:

```bash
bash <(curl -s https://raw.githubusercontent.com/mansnetworker/Turbo-Firewall/main/turbofirewall.sh)

با نصب این اسکریپت، از شر Netscan/Abuse خلاص شوید. این اسکریپت به طور پیش‌فرض تمام پورت‌ها را مسدود می‌کند به جز پورت‌های HTTP (80) و HTTPS (443).
(8080,8443,2053,2087,2096,......)
اگر می‌خواهید پورت خاصی را باز کنید، کافی است گزینه ۲ (Allow Port) را انتخاب کنید و پورت دلخواه خود را وارد کنید.

برای حذف تمام قوانین فایروال اسکریپت، کافی است گزینه ۳ (Uninstall) را انتخاب کنید تا تمامی تنظیمات فایروال به حالت اولیه بازگردد.
