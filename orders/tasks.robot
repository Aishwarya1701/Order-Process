*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             Collections
Library             OperatingSystem
Library             RPA.RobotLogListener
Library             RPA.Desktop


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        ${screenshot}=    Take a screenshot of the robot
        ${pdf}=    Store receipt as a PDF file    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another Robot
    END
    Create a ZIP file of receipt PDF files
    [Teardown]    Close The Browser


*** Keywords ***
Open the robot order website
    Create Directory    ${CURDIR}${/}output
    Create Directory    ${CURDIR}${/}image_files
    Create Directory    ${CURDIR}${/}pdf_files

    Empty Directory    ${CURDIR}${/}image_files
    Empty Directory    ${CURDIR}${/}pdf_files
    Empty Directory    ${CURDIR}${/}output
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    path=${CURDIR}${/}orders.csv
    RETURN    ${table}

Close the annoying modal
    Wait And Click Button    css:button.btn-warning

Fill the form
    [Arguments]    ${order}

    Wait Until Element Is Visible    id:head
    Wait Until Element Is Enabled    id:head
    Set Local Variable    ${order_no}    ${order}[Order number]
    Select From List By Value    id:head    ${order}[Head]

    Wait Until Element Is Enabled    body
    Select Radio Button    body    ${order}[Body]

    Wait Until Element Is Enabled    css:Input.form-control
    Input Text    css:Input.form-control    ${order}[Legs]
    Wait Until Element Is Enabled    id:address
    Input Text    id:address    ${order}[Address]

Preview the robot
    Wait And Click Button    id:preview
    Wait Until Element Is Enabled    id:robot-preview-image
    Set Local Variable    ${image}    id:robot-preview-image

Submit The Order
    Mute Run On Failure    Page Should Contain Element
    Wait And Click Button    id:order
    Page Should Contain Element    id:receipt

Take a screenshot of the robot
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    css:p.badge-success
    ${orderid}=    Get Text    css:p.badge-success
    Sleep    2s
    Set Local Variable    ${image_path}    ${CURDIR}${/}image_files${/}${orderid}.png
    Capture Element Screenshot    id:robot-preview-image    ${image_path}

    RETURN    ${image_path}

Store receipt as a PDF file
    [Arguments]    ${order_number}
    ${reciept_html}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${pdffile_path}    ${CURDIR}${/}pdf_files${/}${order_number}.pdf
    Html To Pdf    ${reciept_html}    ${pdffile_path}
    RETURN    ${pdffile_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}    ${pdf}

Order another Robot
    Wait And Click Button    id:order-another

Create a ZIP file of receipt PDF files
    Set Local Variable    ${zip_file}    ${CURDIR}${/}output${/}receipts.zip
    Archive Folder With ZIP    ${CURDIR}${/}pdf_files    ${zip_file}    recursive=True    include=*.pdf

Close The Browser
    Close Browser
