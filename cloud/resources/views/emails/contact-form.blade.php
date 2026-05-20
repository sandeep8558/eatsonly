<x-mail::message>
# 🍽️ New Inquiry from EatsOnly

You have received a new message through the website contact form.

<x-mail::panel>
### Sender Details
**Name:** {{ $firstName }} {{ $lastName }}  
**Email:** [{{ $email }}](mailto:{{ $email }})  
**Mobile:** [{{ $mobile }}](tel:{{ $mobile }})
</x-mail::panel>

### 💬 Message Content
{{ $messageBody }}

<x-mail::button :url="config('app.url')" color="primary">
Visit Website
</x-mail::button>

Regards,  
**{{ config('app.name') }} Team**
</x-mail::message>
