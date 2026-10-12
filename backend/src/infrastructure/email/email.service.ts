import nodemailer, { type Transporter } from 'nodemailer';
import { logger } from '../logger/logger.service';

export interface SendAccountCreatedEmailParams {
  to: string;
  name: string;
  role: string;
  activationLink: string;
  tempPassword?: string;
  collegeName?: string;
}

export interface SendVerificationOtpEmailParams {
  to: string;
  name: string;
  otp: string;
  activationLink?: string;
}

export interface SendPasswordResetOtpEmailParams {
  to: string;
  name: string;
  otp: string;
}

class EmailService {
  private transporter: Transporter | null = null;
  private isConfigured = false;

  public get isEmailConfigured(): boolean {
    return this.isConfigured;
  }

  constructor() {
    this.initializeTransporter();
  }

  private initializeTransporter() {
    const host = process.env.SMTP_HOST?.trim();
    const port = Number(process.env.SMTP_PORT) || 587;
    const user = process.env.SMTP_USER?.trim();
    const rawPass = process.env.SMTP_PASS?.trim();
    const pass = rawPass ? rawPass.replace(/\s+/g, '') : undefined;

    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
      this.isConfigured = true;
      logger.info({ host, port, user }, 'SMTP email transporter initialized');

      // Asynchronously verify transporter credentials (skip in test environment)
      if (process.env.NODE_ENV !== 'test') {
        this.transporter.verify((error) => {
          if (error) {
            logger.error({ error: error.message }, 'SMTP connection verification failed. Check email and app password credentials.');
          } else {
            logger.info('SMTP mail server is connected and ready to dispatch real emails.');
          }
        });
      }
    } else {
      this.isConfigured = false;
      logger.info('SMTP credentials not provided in environment; using simulated institutional email dispatcher.');
    }
  }

  /**
   * Dispatches email notification to a user when their account is created by an administrator.
   */
  async sendAccountCreatedNotification(params: SendAccountCreatedEmailParams): Promise<boolean> {
    const { to, name, role, activationLink, tempPassword, collegeName } = params;
    const institution = collegeName || 'CampusHub Institution';

    const subject = `Welcome to CampusHub - Your Official ${role} Account Details`;
    const textBody = `
======================================================================
  [CAMPUSHUB INSTITUTIONAL NOTIFICATION] ACCOUNT CREATED
  To: ${to} (${name})
  Role: ${role}
  Institution: ${institution}
  
  Dear ${name},
  An official ${role} account has been provisioned for you by the campus administration.
  
  To activate your account and complete your security credentials:
  1. Open your activation link: ${activationLink}
  2. Request and verify your 6-digit email OTP.
  3. Set your secure account password.
  ${tempPassword ? `\n  Temporary Password: ${tempPassword}\n` : ''}
  
  If you have questions, please reach out to your campus administrator.
======================================================================
    `.trim();

    const htmlBody = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #1a73e8; margin-top: 0;">Welcome to CampusHub</h2>
        <p>Dear <strong>${name}</strong>,</p>
        <p>Your institutional <strong>${role}</strong> account has been created by the administration for <strong>${institution}</strong>.</p>
        <div style="background-color: #f1f3f4; padding: 16px; border-radius: 6px; margin: 20px 0;">
          <p style="margin: 0 0 8px 0;"><strong>Account Email:</strong> ${to}</p>
          <p style="margin: 0 0 8px 0;"><strong>Designated Role:</strong> ${role}</p>
          ${tempPassword ? `<p style="margin: 0 0 8px 0;"><strong>Temporary Password:</strong> <code>${tempPassword}</code></p>` : ''}
        </div>
        <p>Please click the button below to verify your email, set your account password, and finish onboarding:</p>
        <p style="text-align: center; margin: 28px 0;">
          <a href="${activationLink}" style="background-color: #1a73e8; color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; display: inline-block;">Activate Your Account</a>
        </p>
        <p style="color: #5f6368; font-size: 13px;">Or copy and paste this link in your browser:<br/><a href="${activationLink}">${activationLink}</a></p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 24px 0;" />
        <p style="color: #80868b; font-size: 12px;">This is an automated institutional message from CampusHub. Please do not reply directly to this email.</p>
      </div>
    `;

    console.log(textBody);
    logger.info({ to, role, activationLink }, 'Account creation email dispatched to user');

    if (this.isConfigured && this.transporter && process.env.NODE_ENV !== 'test') {
      try {
        await this.transporter.sendMail({
          from: process.env.SMTP_FROM || `"CampusHub Administration" <no-reply@campushub.edu>`,
          to,
          subject,
          text: textBody,
          html: htmlBody,
        });
        return true;
      } catch (err) {
        logger.error({ err, to }, 'Failed to deliver account creation email via SMTP');
        return false;
      }
    }

    return true;
  }

  /**
   * Dispatches 6-digit OTP verification code strictly via email for first-time login / password setup.
   */
  async sendVerificationOtpEmail(params: SendVerificationOtpEmailParams): Promise<boolean> {
    const { to, name, otp } = params;

    const subject = `CampusHub Security - Your 6-Digit Email Verification Code`;
    const textBody = `
======================================================================
  [CAMPUSHUB EMAIL SERVICE] INSTITUTIONAL VERIFICATION OTP
  To: ${to} (${name})
  Subject: ${subject}
  
  Your 6-Digit Email Verification Code (OTP): ${otp}
  
  This verification code will expire in 15 minutes.
  Enter this OTP in the CampusHub app to verify your identity.
======================================================================
    `.trim();

    const htmlBody = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #1a73e8; margin-top: 0;">Institutional Email Verification</h2>
        <p>Dear <strong>${name}</strong>,</p>
        <p>We received a request to verify your institutional account for first-time access or password setup.</p>
        <div style="background-color: #e8f0fe; border: 1px solid #d2e3fc; padding: 18px; border-radius: 8px; text-align: center; margin: 24px 0;">
          <span style="font-size: 13px; color: #1a73e8; text-transform: uppercase; font-weight: bold; letter-spacing: 1px;">Your Verification Code</span>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #174ea6; margin-top: 8px;">${otp}</div>
        </div>
        <p style="font-size: 14px; color: #3c4043;">Enter this 6-digit OTP code in the CampusHub application to confirm your email address. This code expires in <strong>15 minutes</strong>.</p>
        <p style="font-size: 13px; color: #5f6368;">For your security, never share this verification code with anyone.</p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 24px 0;" />
        <p style="color: #80868b; font-size: 12px;">If you did not initiate this request, please contact your college administrator immediately.</p>
      </div>
    `;

    if (process.env.NODE_ENV !== 'production') {
      console.log(textBody);
    }
    logger.info({ to }, 'Verification OTP email dispatched to user');

    if (this.isConfigured && this.transporter && process.env.NODE_ENV !== 'test') {
      try {
        await this.transporter.sendMail({
          from: process.env.SMTP_FROM || `"CampusHub Security" <no-reply@campushub.edu>`,
          to,
          subject,
          text: textBody,
          html: htmlBody,
        });
        return true;
      } catch (err) {
        logger.error({ err, to }, 'Failed to deliver verification OTP email via SMTP');
        return false;
      }
    }

    return true;
  }

  /**
   * Dispatches 6-digit password reset OTP email with zero links.
   */
  async sendPasswordResetOtpEmail(params: SendPasswordResetOtpEmailParams): Promise<boolean> {
    const { to, name, otp } = params;
    const subject = 'CampusHub Security - Password Reset Verification Code';
    const textBody = `
======================================================================
  [CAMPUSHUB SECURITY] PASSWORD RESET VERIFICATION OTP
  To: ${to} (${name})
  Subject: ${subject}
  
  Dear ${name},
  We received a request to reset your password for CampusHub.
  
  Your 6-Digit Password Reset Code (OTP): ${otp}
  
  This verification code will expire in 15 minutes.
  Enter this code in the CampusHub app to continue setting your new password.
  If you did not request this, you can safely ignore this email.
======================================================================
    `.trim();

    const htmlBody = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #1a73e8; margin-top: 0;">Password Reset Verification</h2>
        <p>Dear <strong>${name}</strong>,</p>
        <p>We received a request to reset your password for your CampusHub account.</p>
        <div style="background-color: #fef7e0; border: 1px solid #feefc3; padding: 18px; border-radius: 8px; text-align: center; margin: 24px 0;">
          <span style="font-size: 13px; color: #b06000; text-transform: uppercase; font-weight: bold; letter-spacing: 1px;">Password Reset Code</span>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #202124; margin-top: 8px;">${otp}</div>
        </div>
        <p style="font-size: 14px; color: #3c4043;">Enter this 6-digit verification code in the CampusHub application to set your new password. This code expires in <strong>15 minutes</strong>.</p>
        <p style="font-size: 13px; color: #5f6368;">Never share this verification code with anyone. CampusHub administrators will never ask for your code.</p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 24px 0;" />
        <p style="color: #80868b; font-size: 12px;">This code will expire in 15 minutes. If you did not request a password reset, please ignore this email or contact administration.</p>
      </div>
    `;

    if (process.env.NODE_ENV !== 'production') {
      console.log(textBody);
    }
    logger.info({ to }, 'Password reset OTP email dispatched');

    if (this.isConfigured && this.transporter && process.env.NODE_ENV !== 'test') {
      try {
        await this.transporter.sendMail({
          from: process.env.SMTP_FROM || `"CampusHub Security" <no-reply@campushub.edu>`,
          to,
          subject,
          text: textBody,
          html: htmlBody,
        });
        return true;
      } catch (err) {
        logger.error({ err, to }, 'Failed to deliver password reset OTP email via SMTP');
        return false;
      }
    }

    return true;
  }

  /**
   * Backward compatible password reset email method
   */
  async sendPasswordResetEmail(params: { to: string; name: string; resetLink?: string; resetToken?: string }): Promise<boolean> {
    const rawOtp = params.resetToken ? params.resetToken.slice(0, 6) : '123456';
    return this.sendPasswordResetOtpEmail({ to: params.to, name: params.name, otp: rawOtp });
  }
}

export const emailService = new EmailService();
