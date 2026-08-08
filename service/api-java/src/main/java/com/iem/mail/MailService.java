package com.iem.mail;

import com.iem.exception.ApiException;
import com.resend.Resend;
import com.resend.services.emails.model.CreateEmailOptions;
import com.resend.services.emails.model.CreateEmailResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

@Component
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);

    private final Resend client;
    private final String senderEmail;
    private final String senderName;

    public MailService(@Value("${resend.api.key}") String apiKey,
                       @Value("${resend.sender.email}") String senderEmail,
                       @Value("${resend.sender.name}") String senderName) {
        this.client = new Resend(apiKey);
        this.senderEmail = senderEmail;
        this.senderName = senderName;
    }

    private boolean send(String to, String subject, String html) {
        try {
            CreateEmailOptions request = CreateEmailOptions.builder()
                    .from(senderName + " <" + senderEmail + ">")
                    .to(to)
                    .subject(subject)
                    .html(html)
                    .build();
            CreateEmailResponse response = client.emails().send(request);
            log.info("Email sent to {} (id={})", to, response.getId());
            return true;
        } catch (Exception e) {
            log.error("Failed to send email to {}: {}", to, e.getMessage());
            return false;
        }
    }

    public void sendOtpEmail(String to, String otp) {

        String html = String.format(card("""
                <h2 style="color:#0F172A;margin-bottom:16px;">Verify your email</h2>
                <p style="color:#475569;margin-bottom:24px;">Use the code below to finish creating your account.</p>
                <div style="font-size:32px;font-weight:700;color:#0E7C66;letter-spacing:6px;margin-bottom:24px;">%s</div>
                <p style="font-size:13px;color:#94A3B8;">This code expires in 10 minutes.</p>
                """), otp);

        if (!send(to, "Verify your email - " + senderName, html)) {
            throw new ApiException("Failed to send verification email. Please try again.", 502);
        }
    }

    @Async
    public void sendWelcomeEmail(String to, String fullName) {

        String html = String.format(card("""
                <h2 style="color:#0F172A;margin-bottom:16px;">Welcome, %s</h2>
                <p style="color:#475569;margin-bottom:16px;">Your account is ready.</p>
                <p style="color:#475569;">Start segregating waste, earning points, and helping your community
                recycle better.</p>
                """), fullName);

        send(to, "Welcome to " + senderName, html);
    }

    @Async
    public void sendLoginAlertEmail(String to, String ip) {

        String when = ZonedDateTime.now(ZoneOffset.UTC)
                .format(DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm 'UTC'"));
        String address = (ip == null || ip.isBlank()) ? "unknown" : ip;

        String html = String.format(card("""
                <h2 style="color:#0F172A;margin-bottom:16px;">New sign-in to your account</h2>
                <p style="color:#475569;margin-bottom:8px;">Time: %s</p>
                <p style="color:#475569;margin-bottom:24px;">IP address: %s</p>
                <p style="font-size:13px;color:#94A3B8;">If this wasn't you, change your password immediately.</p>
                """), when, address);

        send(to, "New sign-in to your " + senderName + " account", html);
    }

    @Async
    public void sendPickupAvailableEmail(String to, String address, String materials,
                                         String currency, BigDecimal estimatedOffer) {

        String value = estimatedOffer == null ? "-" : currency + " " + estimatedOffer;
        String items = (materials == null || materials.isBlank()) ? "Mixed waste" : materials;

        String html = String.format(card("""
                <h2 style="color:#0F172A;margin-bottom:16px;">New pickup available</h2>
                <p style="color:#475569;margin-bottom:8px;"><strong>Waste:</strong> %s</p>
                <p style="color:#475569;margin-bottom:8px;"><strong>Estimated value:</strong> %s</p>
                <p style="color:#475569;margin-bottom:24px;"><strong>Address:</strong> %s</p>
                <p style="font-size:13px;color:#94A3B8;">Open the app to accept it. Pickups are
                first come, first served.</p>
                """), items, value, address);

        send(to, "New pickup available - " + senderName, html);
    }

    @Async
    public void sendPickupAcceptedEmail(String to, String collectorName, String address) {

        String html = String.format(card("""
                <h2 style="color:#0F172A;margin-bottom:16px;">Your pickup was accepted</h2>
                <p style="color:#475569;margin-bottom:8px;"><strong>%s</strong> has accepted your
                pickup request and will collect from:</p>
                <p style="color:#475569;margin-bottom:24px;">%s</p>
                <p style="font-size:13px;color:#94A3B8;">This pickup can no longer be cancelled.
                Contact the collector through the app if your plans change.</p>
                """), collectorName, address);

        send(to, "Your pickup was accepted - " + senderName, html);
    }

    private String card(String body) {
        return """
                <div style="background:#F1F5F9;padding:40px 20px;font-family:Arial,sans-serif;text-align:center;">
                  <div style="max-width:520px;margin:0 auto;background:#FFFFFF;border-radius:16px;padding:32px;">
                    <h1 style="color:#0E7C66;margin-bottom:24px;">%s</h1>
                    %s
                  </div>
                </div>
                """.formatted(senderName, body);
    }
}
