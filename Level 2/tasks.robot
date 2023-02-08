*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries INC
...                 Saves the order HTML receipt as PDF file
...                 saves the Screenshot of the ordered robot
...                 Embeds the screenshot of the robot to the PDF receipt
...                 creates ZIP archive of the receipts and the images

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Tables
Library             RPA.HTTP
Library             Dialogs
Library             RPA.PDF
Library             RPA.Desktop
Library             RPA.FileSystem
Library             RPA.Images
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Orders robots from RobotSpareBin Industries INC
    Download the orders
    open the robot order website
    Get orders
    zip Orders


*** Keywords ***
open the robot order website
    ${Secret}=    Get Secret    OrderURL
    Open Available Browser    ${Secret}[URL]
    Wait Until Page Contains Element    css:button.btn.btn-danger

Close pop-up
    Wait Until Page Contains Element    css:button.btn.btn-danger
    Click Button    css:button.btn.btn-danger

Download the orders
    ${OrderURL}=    ask for user input
    Download    ${OrderURL}    overwrite=True

Get orders
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Close pop-up
        Fill one order    ${order}
        Save to PDF    ${order}
        Click Button    id:order-another
    END

submit order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Fill one order
    [Arguments]    ${order}
    Select From List By Index    id:head    ${order}[Head]
    Click Button    id:id-body-${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Preview the robot
    Wait Until Keyword Succeeds    2min    300ms    submit order

Preview the robot
    Click Button    id:preview

Save to PDF
    [Arguments]    ${order}
    Set Local Variable    ${receipt_path}    ${OUTPUT_DIR}${/}receiptsPDF${/}${order}[Order number].pdf
    Set Local Variable    ${screenshot_path}    ${OUTPUT_DIR}${/}receiptsScreenshots${/}${order}[Order number].PNG
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Html To Pdf    ${receipt}    ${receipt_path}
    ${screenshot}=    Screenshot    id:robot-preview-image    ${screenshot_path}

    combine receipt with screenshot    ${receipt_path}    ${screenshot_path}

combine receipt with screenshot
    [Arguments]    ${receipt_path}    ${screenshot_path}
    ${opened_PDF}=    Open Pdf    ${receipt_path}
    ${temp_list}=    Create List    ${screenshot_path}:allign=center

    Add Files To Pdf    ${temp_list}    ${receipt_path}    append=True
    Close Pdf    ${opened_PDF}

zip Orders
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receiptsPDF    ${OUTPUT_DIR}${/}PDFs.zip

ask for user input
    Add heading    Insert order data
    Add text input    url    label=add CSV link    placeholder=CSV link here    rows=1
    ${dialogResults}=    Run dialog
    RETURN    ${dialogResults.url}
