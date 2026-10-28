# أبو فواز — نشر على Vercel

1. Supabase: أنشئ مشروع جديد، افتح SQL Editor والصق schema.sql كله وشغّله.
2. Project Settings → API: انسخ Project URL و anon public key وحطهم في config.js.
3. Vercel: ارفع المجلد ده على GitHub، وبعدين Add New → Project → اختار الريبو، وما تغيّرش أي إعداد (Framework: Other، مفيش build). اضغط Deploy.
   أو من الترمنال: npm i -g vercel ثم vercel --prod جوه المجلد.
