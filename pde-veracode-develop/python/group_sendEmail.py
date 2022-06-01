import smtplib, os
import email.utils
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from markdownify import markdownify

def send(
    REPORT_TYPE="",
    SENDER_SMTP='NO-REPLY@spectrumtoolbox.com',
    SENDER_NAME_SMTP='NO-REPLY@spectrumtoolbox.com',
    RECIPIENT=["c-chenhao.cheng@charter.com"],
    USERNAME_SMTP=os.getenv("DEFAULT_SMTP_USERNAME"),
    PASSWORD_SMTP=os.getenv("DEFAULT_SMTP_PASSWORD"),
    HOST_SMTP=os.getenv("DEFAULT_SMTP_HOST"),
    flaws=None
):
    if(REPORT_TYPE == "weekend_sca"):
        SUBJECT = "(Veracode) High/Very High risk(s) in SCA (Software Composition Analysis)"
        BODY_HTML = """
            <html>
            <head></head>
                <body>
                <h3>Warning!</h3>
                    <h3>Risky vulnerabilities (Policy violations) in the Dependencies / SCA scan</h3>
                    <h3>Please log in Veracode to see full results <a href='https://web.analysiscenter.veracode.com/login/#/login'>Login Veracode</a></h3>
                <br>
        """.format()

        for flaw in list(flaws):
            BODY_HTML = BODY_HTML + """
                <h3>Application: """ + flaw["app_name"] + """</h3>"""

            for report in flaw["reports"]:
                BODY_HTML = BODY_HTML + """
                    <ul>
                        <li>Package: """ + report + """
                    """

                for item in flaw["reports"][report]:
                    BODY_HTML = BODY_HTML + """
                    <ul>
                        <li>Severity: {severity}</li>
                        <li>Library: {library}</li>
                        <li>Summary: {summary}</li>
                    </ul>
                    </li>
                    <br>
                    """.format(**item)

                BODY_HTML = BODY_HTML + """
                    </li>
                    </ul>
                """

        BODY_HTML = BODY_HTML + """
            </body>
            </html>
        """
                
    if(REPORT_TYPE == "weekend_code"):

        SUBJECT = "(Veracode) High/Very High risk(s) in following application(s)"
        BODY_HTML = """
            <html>
            <head></head>
                <body>
                <h3>This is a group scanning/analizing</h3>
                <h3>Please review the following application(s) alone with risk(s)</h3>
                <h3>Please log in Veracode to see full results <a href='https://web.analysiscenter.veracode.com/login/#/login'>Login Veracode</a></h3>
                <br>
        """

        for flaw in list(flaws):
            very_high_severity = []
            high_severity = []
            medium_severity = []
            low_severity = []
            very_low_severity = []
            informational_severity = []
            none_severity = []

            for item in flaw["flaws"]:
                if(item["severity"] == "N/A"):
                    none_severity.append(flaw)
                else:
                    if(item["severity"] == 5):
                        very_high_severity.append(flaw)
                    if(item["severity"] == 4):
                        high_severity.append(flaw)
                    if(item["severity"] == 3):
                        medium_severity.append(flaw)
                    if(item["severity"] == 2):
                        low_severity.append(flaw)
                    if(item["severity"] == 1):
                        very_low_severity.append(flaw)
                    if(item["severity"] == 0):
                        informational_severity.append(flaw)

            if(len(none_severity) > 0):
                BODY_HTML = BODY_HTML + """
                    <h2>Application: {APP_NAME}</h2>
                    <h3>There's no <b>High / Very High</b> risk(s)</h3>
                    <br>
                    """.format(
                        APP_NAME=flaw["app_name"]
                    )
            else:
                BODY_HTML = BODY_HTML + """
                    <h2>Application: {APP_NAME}</h2>
                    <ul>
                        <li>There is/are {very_high_risk_num} Very High flaw(s)</li>
                        <li>There is/are {high_severity_num} High flaw(s)</li>
                        <li>There is/are {medium_severity_num} Medium flaw(s)</li>
                        <li>There is/are {low_severity_num} Low flaw(s)</li>
                        <li>There is/are {very_low_severity_num} Very Low flaw(s)</li>
                        <li>There is/are {informational_severity_num} Information flaw(s)</li>
                    </ul>
                    <br>
                    """.format(
                        APP_NAME=flaw["app_name"],
                        very_high_risk_num=len(very_high_severity),
                        high_severity_num=len(high_severity),
                        medium_severity_num=len(medium_severity),
                        low_severity_num=len(low_severity),
                        very_low_severity_num=len(very_low_severity),
                        informational_severity_num=len(informational_severity)
                    )

        BODY_HTML = BODY_HTML + """
            </li>
            </ul>
        """

    msg = MIMEMultipart('alternative')
    msg['Subject'] = SUBJECT
    msg['From'] = email.utils.formataddr((SENDER_NAME_SMTP, SENDER_SMTP))
    msg['To'] = ", ".join(RECIPIENT)

    # Record the MIME types of both parts - text/plain and text/html.
    part2 = MIMEText(BODY_HTML, 'html')

    # Attach parts into message container.
    # According to RFC 2046, the last part of a multipart message, in this case
    # the HTML message, is best and preferred.
    msg.attach(part2)

    # Try to send the message.
    try:
        server = smtplib.SMTP(HOST_SMTP, 587)
        server.ehlo()
        server.starttls()
        #stmplib docs recommend calling ehlo() before & after starttls()
        server.ehlo()
        server.login(USERNAME_SMTP, PASSWORD_SMTP)

        ### a trace of client/serverinteractions
        # server.set_debuglevel(1) 
        server.sendmail(SENDER_SMTP, RECIPIENT, msg.as_string())
        server.close()
    # Display an error message if something goes wrong.
    except Exception as e:
        print ("Error in sending email: ", e)
    else:
        if(REPORT_TYPE == "weekend_code"):
            print ("Found High/Very High risk scan result. A warning email sent to ", RECIPIENT)
        if(REPORT_TYPE == "weekend_sca"):
            print ("Found risk(s) in dependencies / SCA scan. A warning email sent to ", RECIPIENT)
