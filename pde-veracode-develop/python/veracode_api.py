from veracode.application import Application
from veracode import SDK
import xml.etree.ElementTree as ET
import sys, time, os, json, subprocess
import sendEmail

def waitUntil(app_name, recipient, avoid_sca_scan=None):
    app = None

    if(not avoid_sca_scan):

        #### This part is for code scan result
        scan_not_ready = True
        while scan_not_ready:
            app = Application(app_name)

            if(app.build.analysis.status == "Results Ready"):
                scan_not_ready = False
                print("\n[+] Pre-scan complete! Analysing the application severity report and SCA report...\n", flush=True)
            else:
                VERACODE_CHECK_INTERVAL = os.getenv("VERACODE_CHECK_INTERVAL")
                print("\n**********")
                print("Note: A scan could take up to few hours, depending how large the application is.", flush=True)
                if(VERACODE_CHECK_INTERVAL):
                    print("Application: " + app_name + " scan result is not ready yet, wait for " + VERACODE_CHECK_INTERVAL + " seconds.", flush=True)
                    print("**********\n")
                    time.sleep(int(VERACODE_CHECK_INTERVAL))
                else:
                    VERACODE_CHECK_INTERVAL = 300
                    print("Application: " + app_name + " scan result is not ready yet, wait for " + str(VERACODE_CHECK_INTERVAL) + " seconds.", flush=True)
                    print("**********\n")
                    time.sleep(VERACODE_CHECK_INTERVAL) # Waits 5 minutes for preformance

        print("\n****************************", flush=True)
        print("Checking application code...", flush=True)
        print("****************************\n", flush=True)
        
        
        flaws = list(app.build.report.flaws)
        if(len(flaws) > 0 and ((flaws[0].severity == 4 and flaws[0].count > 0) or (flaws[0].severity == 5 and flaws[0].count > 0))):
            print("\n[+] You have high/very high risk(s) in the application: " + app_name, flush=True)
            print("\n")

            ### Currently, Veracode only support 4.0 for API in DetailedReportPDF, but this library is using 5.0.
            ### But, SummaryReportPDF is using 4.0, however, xml.parsers.expat.ExpatError: not well-formed (invalid token): line 1, column 8
            ### Leave it for now, maybe later on they will change

            # result = SDK.results.SummaryReportPDF(build_id=app.build.id)
            # result = SDK.results.DetailedReportPDF(build_id=app.build.id)
            # result = DetailedReportPDF(build_id=app.build.id).get()
            # result = DetailedReportPDF(app_name)

            try:
                result = SDK.results.SummaryReportPDF(build_id=app.build.id)
                print("result.__dict__")
                print(result.__dict__)
            except ET.ParseError as e:
                print("ParseError:", e)
                pass
            except Exception as e:
                print("Exception: ", e)
                pass


            ## Remote
            sendEmail.send(
                REPORT_TYPE="code",
                SENDER_SMTP=os.getenv("SENDER_SMTP"),
                SENDER_NAME_SMTP=os.getenv("SENDER_NAME_SMTP"),
                RECIPIENT=[x.strip(" ") for x in recipient],
                USERNAME_SMTP=os.getenv("USERNAME_SMTP"),
                PASSWORD_SMTP=os.getenv("PASSWORD_SMTP"),
                HOST_SMTP=os.getenv("HOST_SMTP"),
                APP_NAME=app_name,
                flaws=flaws
            )

            ### Only VERACODE_WEBEX_ROOM_NAME has been set, then veracode bot sent out message
            subprocess.check_call(['/veracode/scripts/webex_msg.sh', app_name])
        else:
            print("\n[+] Application: ", app_name, "has NONE High/Very High vulnerability in application!", flush=True)

        ##################################################################
        ### Generate Detailed report pdf
        bid = app.build.id
        cuspath = "./"
        detailed_pdf_filename = app_name.replace(" ", "-") + ".pdf"
        os.system('java -jar vosp-api-wrappers-java-' + os.getenv("VERACODE_WRAPPER_VERSION") +'.jar -action detailedreport -buildid '+ str(bid) +' -format pdf -outputfilepath '+ cuspath + detailed_pdf_filename)

        ##################################################################
        #### This part is for SCA result
        report = vars(app.build.report)
        print("\n****************************", flush=True)
        print("Checking application SCA...", flush=True)
        print("****************************\n", flush=True)
        if(report["policy_rules_status"] == "Did Not Pass"):
            sca_flaws = {}
            for component in app.build.report.software_composition_analysis.vulnerable_components.component:
                if(component.vulnerabilities[0] != 0 and component.vulnerabilities[1] != None and component.violated_policy_rules != None):
                    component = vars(component)
                    if(component["file_name"] not in sca_flaws):
                        sca_flaws[component["file_name"]] = []

                    ### Either a list of object or just a single object
                    if(type(component["vulnerabilities"][1].vulnerability) is list):
                        for vulnerability in component["vulnerabilities"][1].vulnerability:
                            vulnerability = vars(vulnerability)
                            temp_dict = {}

                            temp_dict["library"] = component["library_id"]
                            temp_dict["severity"] = vulnerability["severity"]
                            temp_dict["summary"] = vulnerability["cve_summary"]
                            sca_flaws[component["file_name"]].append(temp_dict)

                    else:
                        ### If the type is not list, it will be custom object
                        vulnerability = vars(component["vulnerabilities"][1].vulnerability)
                        temp_dict = {}

                        temp_dict["library"] = component["library_id"]
                        temp_dict["severity"] = vulnerability["severity"]
                        temp_dict["summary"] = vulnerability["cve_summary"]
                        sca_flaws[component["file_name"]].append(temp_dict)

            # print("\nsca_flaws: ", json.dumps(sca_flaws, sort_keys=True, indent=4))

            if(os.getenv("VERACODE_WEBEX_ROOM_NAME")):
                ### This is for detailed report
                os.environ['DETAILED_PDF_FILE_LOCATION'] = cuspath + detailed_pdf_filename

                ### This is for json file
                json_file_name = app_name.replace(" ", "-") + "_sca_scan_result.json"
                json_file_location = "/tmp/" + json_file_name
                os.environ['SCA_FILE_LOCATION'] = json_file_location
                with open(json_file_location, "w") as sca_json_file:
                    sca_json_file.write(json.dumps(sca_flaws, sort_keys=True, indent=4))
                    print("Generated " + json_file_name + " file because there's high/very high risk(s)\n", flush=True)

            ### Only VERACODE_WEBEX_ROOM_NAME has been set, then veracode bot sent out message
            subprocess.check_call(['/veracode/scripts/webex_msg.sh', app_name])

            if(sca_flaws):
                ### Remote
                sendEmail.send(
                    REPORT_TYPE="sca",
                    SENDER_SMTP=os.getenv("SENDER_SMTP"),
                    SENDER_NAME_SMTP=os.getenv("SENDER_NAME_SMTP"),
                    RECIPIENT=[x.strip(" ") for x in recipient],
                    USERNAME_SMTP=os.getenv("USERNAME_SMTP"),
                    PASSWORD_SMTP=os.getenv("PASSWORD_SMTP"),
                    HOST_SMTP=os.getenv("HOST_SMTP"),
                    APP_NAME=app_name,
                    flaws=sca_flaws,
                    cuspath=cuspath,
                    detailed_pdf_filename=detailed_pdf_filename
                )
        else:
            ### If SCA result is passing;
            ### If it's passing, checking if customer has set VERACODE_GRAB_DETAILED_REPORT. Send out report anyway if it's set
            if(os.getenv("VERACODE_WEBEX_ROOM_NAME") and os.getenv("VERACODE_GRAB_DETAILED_REPORT")):
                print("There is no SCA risk(s), customer still wants a detailed report", flush=True)
                os.environ['DETAILED_PDF_FILE_LOCATION'] = cuspath + detailed_pdf_filename
                subprocess.check_call(['/veracode/scripts/webex_msg.sh', app_name])
            else:
                print("\n[+] Application: ", app_name, "has NONE vulnerability in Dependencies / SCA!", flush=True)

    else:
        print("\nVERACODE_SCAN_GITLAB_GROUP is set, so it will be running group", flush=True)


if __name__ == "__main__":

    waitUntil(sys.argv[1], sys.argv[2].split(","), sys.argv[3])
