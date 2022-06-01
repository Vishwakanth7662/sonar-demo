import smtplib, os, boto3
import email.utils
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from markdownify import markdownify
from botocore.exceptions import ClientError


def send(
    REPORT_TYPE="",
    SENDER_SMTP='NO-REPLY@spectrumtoolbox.com',
    SENDER_NAME_SMTP='NO-REPLY@spectrumtoolbox.com',
    RECIPIENT=["c-chenhao.cheng@charter.com"],
    USERNAME_SMTP=os.getenv("DEFAULT_SMTP_USERNAME"),
    PASSWORD_SMTP=os.getenv("DEFAULT_SMTP_PASSWORD"),
    HOST_SMTP=os.getenv("DEFAULT_SMTP_HOST"),
    APP_NAME="",
    flaws=None,
    cuspath="./",
    detailed_pdf_filename=""
):

    if(REPORT_TYPE == "code"):
        CHARSET = "utf-8"

        ### flaws is list
        SUBJECT = "(Veracode) High/Very High risk(s) in application code itself"
        msg = MIMEMultipart('mixed')
        msg['Subject'] = SUBJECT
        msg['From'] = email.utils.formataddr((SENDER_NAME_SMTP, SENDER_SMTP))
        msg['To'] = ", ".join(RECIPIENT)

        
        very_high_severity = []
        high_severity = []
        medium_severity = []
        low_severity = []
        very_low_severity = []
        informational_severity = []

        for flaw in list(flaws):
            if(flaw.severity == 5):
                very_high_severity.append(flaw)
            if(flaw.severity == 4):
                high_severity.append(flaw)
            if(flaw.severity == 3):
                medium_severity.append(flaw)
            if(flaw.severity == 2):
                low_severity.append(flaw)
            if(flaw.severity == 1):
                very_low_severity.append(flaw)
            if(flaw.severity == 0):
                informational_severity.append(flaw)
        # The HTML body of the email.
        BODY_HTML = """
            <html>
            <head></head>
                <body>
                <h1><strong>Warning!</strong></h1>
                    <h2>High/Very Risky vulnerability in the application scan itself</h2>
                    <h3>There are total {flaws_num} risks(s) in your application: <b>{APP_NAME}</b></h3>

                    <ul>
                        <li>There is/are {very_high_risk_num} Very High flaw(s)</li>
                        <li>There is/are {high_severity_num} High flaw(s)</li>
                        <li>There is/are {medium_severity_num} Medium flaw(s)</li>
                        <li>There is/are {low_severity_num} Low flaw(s)</li>
                        <li>There is/are {very_low_severity_num} Very Low flaw(s)</li>
                        <li>There is/are {informational_severity_num} Information flaw(s)</li>
                    </ul>

                    <h3>Please log in Veracode to see full results <a href='https://web.analysiscenter.veracode.com/login/#/login'>Login Veracode</a></h3>
                    
                </body>
            </html>
                    """.format(
                        recepients=", ".join(RECIPIENT),
                        flaws_num=len(flaws),
                        APP_NAME=APP_NAME,
                        very_high_risk_num=len(very_high_severity),
                        high_severity_num=len(high_severity),
                        medium_severity_num=len(medium_severity),
                        low_severity_num=len(low_severity),
                        very_low_severity_num=len(very_low_severity),
                        informational_severity_num=len(informational_severity)
                        )

        ### Write markdown file of code scan result
        if(os.getenv("VERACODE_WEBEX_ROOM_NAME")):
            markdown_filename = APP_NAME.replace(" ", "-") + "_code_scan_result.md"
            markdown_file_location = "/tmp/" + markdown_filename
            os.environ['CODE_FILE_LOCATION'] = markdown_file_location
            with open(markdown_file_location, "w") as code_md_file:
                html = markdownify(BODY_HTML, heading_style="ATX")
                code_md_file.write(html)
                print("Generated " + markdown_filename + " because there's high/very high risk(s)\n", flush=True)
    
        
        msg = MIMEMultipart('alternative')
        # Record the MIME types of both parts - text/plain and text/html.
        htmlpart = MIMEText(BODY_HTML.encode(CHARSET), 'html', CHARSET)

        # Attach parts into message container.
        # According to RFC 2046, the last part of a multipart message, in this case
        # the HTML message, is best and preferred.
        msg.attach(htmlpart)

        # Try to send the message.
        try:
            server = smtplib.SMTP(HOST_SMTP, 587)
            server.ehlo()
            server.starttls()
            #stmplib docs recommend calling ehlo() before & after starttls()
            server.ehlo()
            server.login(USERNAME_SMTP, PASSWORD_SMTP)
            server.sendmail(SENDER_SMTP, RECIPIENT, msg.as_string())
            server.close()
        # Display an error message if something goes wrong.
        except Exception as e:
            print ("Error in sending email: ", e)
        else:
            if(REPORT_TYPE == "code"):
                print ("Found High/Very High risk scan result. A warning email sent to ", RECIPIENT)
            if(REPORT_TYPE == "sca"):
                print ("Found risk(s) in dependencies / SCA scan. A warning email sent to ", RECIPIENT)

    if(REPORT_TYPE == "sca"):

        CHARSET = "utf-8"
        client = boto3.client('ses',region_name="us-east-1")
        CONFIGURATION_SET = "ses-config-set"

        SUBJECT = "(Veracode) High/Very High risk(s) in SCA (Software Composition Analysis)"
        msg = MIMEMultipart('mixed')
        msg['Subject'] = SUBJECT
        msg['From'] = email.utils.formataddr((SENDER_NAME_SMTP, SENDER_SMTP))
        msg['To'] = ", ".join(RECIPIENT)
        msg_body = MIMEMultipart('alternative')
        ### flaws is dictionary
        
        BODY_HTML = """
            <html>
            <head></head>
                <body>
                <h1>Warning!</h1>
                    <h2>Risky vulnerabilities (Policy violations) in the Dependencies / SCA scan</h2>
                    <h2>Application: <b>{APP_NAME}</b></h2>
                    <h3>Please log in Veracode to see full results <a href='https://web.analysiscenter.veracode.com/login/#/login'>Login Veracode</a></h3>
                <br>
        """.format(
            recepients=", ".join(RECIPIENT),
            APP_NAME=APP_NAME,
        )

        for flaw in flaws:
            BODY_HTML = BODY_HTML + """
                <ul>
                    <li>Package: """ + flaw + """<br>"""

            for item in flaws[flaw]:
                BODY_HTML = BODY_HTML + """
                <ul>
                    <li>Severity: {severity}</li>
                    <li>Library: {library}</li>
                    <li>Summary: {summary}</li>
                </ul><br>
                """.format(**item)
            
            BODY_HTML = BODY_HTML + """
                </li>
                </ul>
            """

        BODY_HTML = BODY_HTML + """
            </body>
            </html>
        """

        htmlpart = MIMEText(BODY_HTML.encode(CHARSET), 'html', CHARSET)
        msg_body.attach(htmlpart)
        msg.attach(msg_body)

        attach = MIMEApplication(open(cuspath + detailed_pdf_filename, 'rb').read())
        attach.add_header('Content-Disposition','attachment',filename=os.path.basename(cuspath + detailed_pdf_filename))
        msg.attach(attach)

        try:
            #Provide the contents of the email.
            response = client.send_raw_email(
                Source="NO-REPLY@spectrumtoolbox.com",
                Destinations=RECIPIENT,
                # Destinations=[
                #     RECIPIENT,
                # ],
                RawMessage={
                    'Data':msg.as_string(),
                },
                ConfigurationSetName=CONFIGURATION_SET
            )
        # Display an error if something goes wrong.	
        except ClientError as e:
            print(e.response['Error']['Message'])
        else:
            print("Email sent! Message ID:"),
            print(response['MessageId'])

    
