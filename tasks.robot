*** Settings ***
Documentation     This is the robot for the second tutorial.
...               Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library   RPA.Browser.Selenium
Library   RPA.HTTP
Library   RPA.PDF
Library   RPA.Tables
Library   DateTime
Library   RPA.RobotLogListener
Library   RPA.Archive
Library   RPA.FileSystem
Library   RPA.Dialogs
Library   RPA.Robocloud.Secrets


***Keywords***
Open the robot order website
    [Arguments]    ${website_url}
    #https://robotsparebinindustries.com/#/robot-order
    Open Available Browser      ${website_url}[URL]
    ${date}=    Get Current Date    time_zone=UTC   result_format=epoch
    Log     ${date}

***Keywords***
Download The CSV File
    Download    https://robotsparebinindustries.com/orders.csv      overwrite=True


***Keywords***
Read The CSV File
    Download The CSV File
    ${orders}=    Read table from CSV       orders.csv
    [Return]    ${orders}



# +
***Keywords***
Fill the form
    [Arguments]    ${order}
    Click Button    OK  
    #Head
    Select From List By Index    head      ${order}[Head]
    #Body
    ${body_identifier}=     Set Variable    id-body-${order}[Body]
    Click Button      ${body_identifier}
    #Legs
    ${leg_identifier}=    Set Variable          xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input  
    Input Text         ${leg_identifier}        ${order}[Legs]
    #Address
    Input Text         address      ${order}[Address]

    


# -

***Keywords***
Preview the robot
    Click Button    preview
    Wait Until Element Is Visible       robot-preview-image

***Keywords***
Submit the order
    # In Case the Recipe didn't load we won't succeed 
    Mute Run On Failure             Page Should Contain Element 
    
    Click Button        order
    Page Should Contain Element     receipt


***Keywords***
Store the receipt as a PDF file
    [Arguments]    ${Order_number}
    Page Should Contain Element     receipt
    
    ${order_receipt}=    Get Element Attribute      receipt    outerHTML
    Html To Pdf     ${order_receipt}        ${CURDIR}${/}output${/}pdf${/}${Order_number}.pdf 
    [Return]         ${CURDIR}${/}output${/}pdf${/}${Order_number}.pdf 


***Keywords***
Take a screenshot of the robot
    [Arguments]    ${Order_number}
    Wait Until Element Is Visible       robot-preview-image  
    Sleep   1sec
    Capture Element Screenshot      robot-preview-image       ${CURDIR}${/}output${/}img${/}${Order_number}.png      
    [Return]        ${CURDIR}${/}output${/}img${/}${Order_number}.png   

***Keywords***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    
    ${img_file_list}=       Create List     ${screenshot}:x=0,y=0

    
    Add Files To Pdf    ${img_file_list}   ${pdf}   True
    Close Pdf   ${pdf}

***Keywords***
Go to order another robot
    Click Button    order-another


*** Keywords ***
Create a ZIP file of the receipts
    [Arguments]     ${employee_name}
    Create Directory    ${CURDIR}${/}output${/}zip
    Archive Folder With ZIP     ${CURDIR}${/}output${/}pdf${/}  ${CURDIR}${/}output${/}zip${/}all_receips_from_${employee_name}.zip   recursive=True  include=*.pdf

***Keywords***
Get Employee name
    Add text input          employee_name    label=Please enter your employee Name for File identification.     placeholder=Enter Employee Name
    ${result}=              Run dialog
    [Return]                ${result.employee_name }

***Keywords***
Get Site URL from URL
    ${websiteURL}=            Get Secret      URL
    [Return]    ${websiteURL}


***Tasks***
Order robots from RobotSpareBin Industries Inc
    #Additional Task 1: Get User Input
    ${employee_name}=   Get Employee name
    
    #Additional Task 2: Get the URL from the Vault
    ${site_url}=    Get Site URL from URL
    
    Open the robot order website    ${site_url}
    Read The CSV File
    ${orders}=    Read The CSV File
    FOR    ${row}    IN    @{orders}
        Fill the form         ${row}
        #The Wait Until Keywords Succeeds makes sure the Operation  was successfull and retries until it was.
        Preview the robot
        Wait Until Keyword Succeeds     5x      3s      Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts   ${employee_name}
