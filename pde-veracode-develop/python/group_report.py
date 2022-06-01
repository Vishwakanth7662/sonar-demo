
import gitlab, os, re, subprocess, requests, time, json
from gitlab import GitlabError
from veracode.application import Application
from veracode import SDK
import group_sendEmail

def main():
    
    try:
        varacode_app_names = []
        group_flaws = []
        app_reports = []
        app_sca_reports = []

        ### remote
        gl_conn = gitlab.Gitlab(os.getenv("GITLAB_HOST_URL"), private_token=os.getenv("GITLAB_PRIVATE_TOKEN"))

        ### local
        # GITLAB_PRIVATE_TOKEN = ""
        # GITLAB_HOST_URL = ""
        # gl_conn = gitlab.Gitlab(GITLAB_HOST_URL, GITLAB_PRIVATE_TOKEN)

        # 4164, 4165, 4737
        ### 4164: GraphQL: 23
        ### 4165: Spectrum Enterprise: 43
        ### 4737: Components
        # GROUP_IDS = [4165]

        group = gl_conn.groups.get(os.getenv("GITLAB_GROUP_ID"))
        projects = group.projects.list(all=True, include_subgroups=True)
        target_project = None

        ### Filter out repos that start with dgs or DGS
        for project in projects:

            if(bool(re.match("^dgs.*", project.name)) or bool(re.match("^DGS.*", project.name))):
                target_project = gl_conn.projects.get(project.id)

            if(bool(re.match("^enterprise.*", project.name))):
                target_project = gl_conn.projects.get(project.id)

            if(target_project):
                try:
                    VERACODE_APP_NAME = vars(target_project.variables.get("VERACODE_APP_NAME"))["_attrs"]["value"]
                    varacode_app_names.append(VERACODE_APP_NAME)
                    target_project = None
                    
                except gitlab.exceptions.GitlabGetError:
                    pass
            
        ### Local
        # for varacode_app_name in sorted(varacode_app_names)[14:16]:

        ### Remote
        for varacode_app_name in sorted(varacode_app_names):

            # ### only for testing here
            # if(varacode_app_name == "DGS-voice-domain-management"):
            #     app = Application(varacode_app_name)

            #     ### app.build.report.flaws will be listed as sorted from high severity to low
            #     flaws = list(app.build.report.flaws)

            #     if(len(flaws) > 0 and ((flaws[0].severity == 4 and flaws[0].count > 0) or (flaws[0].severity == 5 and flaws[0].count > 0))):
            #         app_flaw = {}
            #         app_flaw["app_name"] = varacode_app_name
            #         app_flaw["flaws"] = flaws
            #         group_flaws.append(app_flaw)

            #     ### SCA vulnerabilities
            #     sca_flaw = {}
            #     sca_flaw["app_name"] = varacode_app_name
            #     sca_flaw["report"] = vars(app.build.report)
            #     app_reports.append(sca_flaw)

            #     # print("group_flaws:", group_flaws)
            #     # print("app_reports: ", app_reports)

            try:
                print(varacode_app_name + " is being analized", flush=True)
                app = Application(varacode_app_name)

                ### Code vulnerabilities
                ### app.build.report.flaws will be listed as sorted from high severity to low
                try:
                    flaws = list(app.build.report.flaws)
                    # ### flaws[0] only shows the highest vulnerability level in a project scan
                    if(len(flaws) > 0 and ((flaws[0].severity == 4 and flaws[0].count > 0) or (flaws[0].severity == 5 and flaws[0].count > 0))):
                        app_flaw = {}
                        app_flaw["app_name"] = varacode_app_name
                        ### I think we needs to extract from the API dict
                        app_flaw["flaws"] = vars(flaws)
                        group_flaws.append(app_flaw)
                
                except:
                    print("There is no flaw(s) in " + varacode_app_name, flush=True)
                    ### Code vulnerabilities
                    app_flaw = {}
                    app_flaw["app_name"] = varacode_app_name
                    app_flaw["flaws"] = [{ "severity": "N/A" }]
                    group_flaws.append(app_flaw)

                try:
                    report = vars(app.build.report)

                    sca_flaw = {}
                    sca_flaw["app_name"] = varacode_app_name
                    sca_flaw["report"] = report
                    app_reports.append(sca_flaw)
                except:
                    
                    ### SCA vulnerabilities
                    sca_flaw = {}
                    sca_flaw["app_name"] = varacode_app_name
                    sca_flaw["report"] = { "policy_rules_status": "N/A" }
                    app_reports.append(sca_flaw)

            except requests.exceptions.Timeout:
                print("Time out")
            except requests.exceptions.TooManyRedirects:
                print("Too many Redirects")
            except requests.exceptions.RequestException as e:
                # catastrophic error. bail.
                raise SystemExit(e)


        if(len(group_flaws) > 0):
            print("There is at least one flaw(s) in the application", flush=True)
            ### Remote
            group_sendEmail.send(
                REPORT_TYPE="weekend_code",
                SENDER_SMTP=os.getenv("SENDER_SMTP"),
                SENDER_NAME_SMTP=os.getenv("SENDER_NAME_SMTP"),
                RECIPIENT=[x.strip() for x in os.getenv("VERACODE_TO_DL_EMAIL").split(",")],
                USERNAME_SMTP=os.getenv("USERNAME_SMTP"),
                PASSWORD_SMTP=os.getenv("PASSWORD_SMTP"),
                HOST_SMTP=os.getenv("HOST_SMTP"),
                flaws=group_flaws
            )

            # ### Only VERACODE_WEBEX_ROOM_NAME has been set, then veracode bot sent out message
            # subprocess.check_call(['/veracode/scripts/webex_msg.sh', app_name])

        ### Loop through all reports in SCA
        if(len(app_reports) > 0):
            for app_report in app_reports:

                app_sca = {}
                if(app_report["report"]["policy_rules_status"] == "N/A"):
                    app_sca["app_name"] = app_report["app_name"]
                    app_sca["reports"] = {
                        "N/A": [{
                            "library": "N/A",
                            "severity": "N/A",
                            "summary": "N/A"
                        }]
                    }

                if(app_report["report"]["policy_rules_status"] == "Did Not Pass"):

                    sca_flaws = {}
                    vulnerable_components = vars(app_report["report"]["software_composition_analysis"].vulnerable_components)
                    for component in vulnerable_components["component"]:
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

                    app_sca["app_name"] = app_report["app_name"]
                    app_sca["reports"] = sca_flaws
                app_sca_reports.append(app_sca)
                            
            # print("\app_sca_reports: ", json.dumps(app_sca_reports, sort_keys=True, indent=4))

        if(len(app_sca_reports) > 0):
            print("There is at least one flaw(s) in the SCA", flush=True)
            ### Remote
            group_sendEmail.send(
                REPORT_TYPE="weekend_sca",
                SENDER_SMTP=os.getenv("SENDER_SMTP"),
                SENDER_NAME_SMTP=os.getenv("SENDER_NAME_SMTP"),
                RECIPIENT=[x.strip() for x in os.getenv("VERACODE_TO_DL_EMAIL").split(",")],
                USERNAME_SMTP=os.getenv("USERNAME_SMTP"),
                PASSWORD_SMTP=os.getenv("PASSWORD_SMTP"),
                HOST_SMTP=os.getenv("HOST_SMTP"),
                flaws=app_sca_reports
            )


            # if(os.getenv("VERACODE_WEBEX_ROOM_NAME")):
            #     json_file_name = app_name.replace(" ", "-") + "_sca_scan_result.json"
            #     json_file_location = "/tmp/" + json_file_name
            #     os.environ['SCA_FILE_LOCATION'] = json_file_location
            #     with open(json_file_location, "w") as sca_json_file:
            #         sca_json_file.write(json.dumps(sca_flaws, sort_keys=True, indent=4))
            #         print("Generated " + json_file_name + " file because there's high/very high risk(s)\n", flush=True)

            # ### Only VERACODE_WEBEX_ROOM_NAME has been set, then veracode bot sent out message
            # subprocess.check_call(['/veracode/scripts/webex_msg.sh', app_name])


    except GitlabError as err:
        raise err
print("Execution of code is completed")
if __name__ == "__main__":
    main()