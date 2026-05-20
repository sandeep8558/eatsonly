<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Mail;
use Exception;

class SaaSMailer
{
    /**
     * Set dynamic configuration and validate Mailgun settings.
     *
     * @throws Exception
     */
    public static function prepare()
    {
        $domain = Setting::get('mailgun_domain');
        $secret = Setting::get('mailgun_secret');
        $fromAddress = Setting::get('mailgun_from_address');
        $fromName = Setting::get('mailgun_from_name');

        if (!$domain || !$secret || !$fromAddress) {
            throw new Exception("Mailgun details not found. Please configure them in SaaS Settings.");
        }

        config([
            'mail.default' => 'mailgun',
            'services.mailgun.domain' => $domain,
            'services.mailgun.secret' => $secret,
            'services.mailgun.endpoint' => 'api.mailgun.net',
            'mail.from.address' => $fromAddress,
            'mail.from.name' => $fromName ?? config('app.name'),
        ]);
    }

    /**
     * Send a mailable using dynamic SaaS settings.
     */
    public static function send($to, $mailable)
    {
        self::prepare();
        return Mail::to($to)->send($mailable);
    }
}
