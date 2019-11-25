//
//  IntroViewController.swift
//  DrawPad
//
//  Created by Andrew Morgan on 18/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import SwiftUI

// global vars
//var agreedToTerms = false  // TODO replace with an IBOutlet

// This is the introducion view
class IntroViewController: BaseViewController {
  
    var agreedToTerms = false
    var gotValidEmail = false  // APPENG-72
    var termsConditionsPrivacyPolicy = """
    1. Purpose of this Privacy Policy.
    MongoDB, Inc. is committed to protecting your privacy. We have prepared this Privacy Policy to describe to you our practices regarding the Personal Data (as defined below) we collect from users of our website located at MongoDB.com and in connection with our MongoDB products and services (the \"Products\"). In addition, this Privacy Policy tells you about your privacy rights and how the law protects you.

    This website is not intended for children and we do not knowingly collect data relating to children.

    It is important that you read this Privacy Policy together with any other privacy notice or fair processing notice we may provide on specific occasions when we are collecting or processing personal data about you so that you are fully aware of how and why we are using your data. This Privacy Policy supplements the other notices and is not intended to override them.

    2. User Acknowledgment.
    By submitting Personal Data through our website or Products, you acknowledge that you have read and understand this Privacy Policy and agree to the terms of this Privacy Policy.

    3. Controller and Contact Details
    MongoDB Inc. (collectively referred to as ”MongoDB”, “we”, “us” or “our” in this privacy notice) is the controller of Personal Data submitted in accordance with this Privacy Policy and is responsible for that Personal Data. We have appointed a data protection officer (DPO) who is responsible for overseeing questions in relation to this Privacy Policy. If you have any questions about this Privacy Policy, including any requests to exercise your legal rights, please contact the DPO using the details set out below.

    Our full details are:

    Full name of legal entity: MongoDB Inc.

    Title of DPO: Legal Director

    Email address: privacy@mongodb.com

    Postal address: 1633 Broadway, 38th Floor New York, NY 10019

    4. Types Of Data We Collect.
    We collect Personal Data and Anonymous Data from you when you visit our site, when you send us information or communications, when you download and use our Products, and when you register for white papers, web seminars, and other events hosted by us. "Personal Data" means data that allows someone to identify or contact you, including, for example, your name, address, telephone number, e-mail address, as well as any other non-public information about you that is associated with or linked to any of the foregoing data. "Anonymous Data" means data that is not associated with or linked to your Personal Data; Anonymous Data does not permit the identification of individual persons. We do not collect any Special Categories of Personal Data about you (this includes details about your race or ethnicity, religious or philosophical beliefs, sex life, sexual orientation, political opinions, trade union membership, information about your health and genetic and biometric data).

    4.1 Personal Data You Provide to Us.
    We collect Personal Data from you, such as your first and last name, e-mail and mailing addresses, professional title, company name, and password when you download and install the Products, create an account to log in to our network, or sign-up for our newsletter or other marketing material. When you order Products on our website, we will collect all information necessary to complete the transaction, including your name, credit card information, billing information and shipping information. We also retain information on your behalf, such as files and messages that you store using your account. If you provide us feedback or contact us via e-mail or submit a response to an employment opportunity posted on our website, we will collect your name and e-mail address, as well as any other content included in the e-mail, in order to send you a reply, and any information that you submit to us, such as a resume. When you participate in one of our surveys, we may collect additional profile information. When you post messages on the message boards of our website, the information contained in your posting will be stored on our servers and other users will be able to see it. We also collect other types of Personal Data that you provide to us voluntarily, such as operating system and version, Product version numbers, and other requested information if you contact us via e-mail regarding support for the Products. We may also collect Personal Data, such as demographic information, from you via the Products or at other points in our website that state that Personal Data is being collected.

    4.2 Personal Data Collected Via Technology.
    To make our website and Products more useful to you, our servers (which may be hosted by a third party service provider) collect Personal Data from you, including browser type, operating system, Internet Protocol (IP) address (a number that is automatically assigned to your computer when you use the Internet, which may vary from session to session), domain name, and/or a date/time stamp for your visit.

    4.3 Personal Data Collected Via Cookies.
    We also use Cookies (as defined below) and navigational data like Uniform Resource Locators (URL) to gather information regarding the date and time of your visit and the solutions and information for which you searched and which you viewed. Like most technology companies, we automatically gather this Personal Data and store it in log files each time you visit our website or access your account on our network. "Cookies" are small pieces of information that a website sends to your computer’s hard drive while you are viewing a web site. We may use both session Cookies (which expire once you close your web browser) and persistent Cookies (which stay on your computer until you delete them) to provide you with a more personal and interactive experience on our website. Persistent Cookies can be removed by following Internet browser help file directions. You may choose to refuse or disable Cookies via the settings on your browser, however by doing so, some areas of our website may not work properly.

    4.4 Personal Data That We Collect From You About Others.
    If you decide to create an account for and invite a third party to join our network, we will collect your and the third party's names and e-mail addresses in order to send an e-mail and follow up with the third party. You or the third party may contact us at privacy@mongodb.com to request the removal of this information from our database.

    5. Use Of Your Data
    5.1 General Use.
    In general, Personal Data you submit to us is used either to respond to requests that you make, or to aid us in serving you better. We use your Personal Data in the ways set out in the table below where we also detail the legal bases we rely on to do so:

    Purpose/Activity    Type of data    Lawful basis for processing including basis of legitimate interest
    To register you as a new customer and provide administration of our website and Products    (a) Identity
    (b) Contact    (a) Performance of a contract with you
    (b) Necessary for our legitimate interests
    To manage our relationship with you which will include:
    (a) Notifying you about changes to our terms or privacy policy
    (b) Asking you to leave a review or take a survey    (a) Identity
    (b) Contact
    (c) Profile
    (d) Marketing and Communications    (a) Performance of a contract with you
    (b) Necessary to comply with a legal obligation
    (c) Necessary for our legitimate interests
    To enable you to partake in a prize draw, competition or complete a survey    (a) Identity
    (b) Contact
    (c) Profile
    (d) Usage
    (e) Marketing and Communications    (a) Performance of a contract with you
    (b) Necessary for our legitimate interests
    To administer and protect our business and this website (including troubleshooting, data analysis, testing, system maintenance, support, reporting and hosting of data)    (a) Identity
    (b) Contact
    (c) Technical    (a) Necessary for our legitimate interests
    (b) Necessary to comply with a legal obligation
    To deliver relevant website content and advertisements to you and measure or understand the effectiveness of the advertising we serve to you    (a) Identity
    (b) Contact
    (c) Profile
    (d) Usage
    (e) Marketing and Communications
    (f) Technical    Necessary for our legitimate interests
    To use data analytics to improve our website, products/services, marketing, customer relationships and experiences    (a) Identity
    (b) Profile
    (c) Technical
    (d) Usage
    Necessary for our legitimate interests
    To make suggestions and recommendations to you about goods or services that may be of interest to you    (a) Identity
    (b) Contact
    (c) Technical
    (d) Usage
    (e) Profile    Necessary for our legitimate interests
    In some contexts, we will ask for explicit consent
    5.2 Creation of Anonymous Data.
    We may create Anonymous Data records from Personal Data by excluding information (such as your name) that makes the data personally identifiable to you. We use this Anonymous Data to analyze request and usage patterns so that we may enhance the content of our Products and improve site navigation, and for marketing and analytics. We reserve the right to use and disclose Anonymous Data to Third Party Companies in our discretion.

    5.3 Feedback.
    If you provide feedback on any of our Products or our website, we may use such feedback for any purpose, provided we will not associate such feedback with your Personal Data. We will collect any information contained in such communication and will treat the Personal Data in such communication in accordance with this Privacy Policy.

    6. Disclosure Of Your Personal Data
    6.1 Affiliates.
    We may share some or all of your Personal Data with other companies under our common control ("Affiliates"), in which case we will require our Affiliates to honor this Privacy Policy. If another company acquires us or our assets, that company will possess the Personal Data collected by it and us and will assume the rights and obligations regarding your Personal Data as described in this Privacy Policy. We may also disclose your Personal Data to third parties in the event that we sell or buy any business or assets, in which case we may disclose your Personal Data to the prospective seller or buyer of such business or assets.

    6.2 Other Disclosures.
    Regardless of any choices you make regarding your Personal Data (as described below), we may disclose Personal Data if we believe in good faith that such disclosure is necessary to (a) comply with relevant laws or to respond to subpoenas or warrants served on us; (b) protect or defend our rights or property or the rights or property of users of the Products; or (c) protect against fraud and reduce credit risk.

    7. Third Parties
    7.1 Personal and/or Anonymous Data Collected By Third Parties.
    (a) We may receive Personal and/or Anonymous Data about you from other sources like telephone or fax, or from companies that provide our Products by way of a co-branded or private-labeled website or companies that offer their products and/or services on our website ("Third Party Companies"). Our Third Party Companies may supply us with Personal Data, such as your calendars and address book information, in order to help us establish the account. We may add this information to the information we have already collected from you via our website in order to improve the Products we provide.

    (b) Our provision of a link to any other website or location is for your convenience and does not signify our endorsement of such other website or location or its contents. When you click on such a link, you will leave our site and go to another site. During this process, another entity may collect Personal Data or Anonymous Data from you.

    (c) We have no control over, do not review, and cannot be responsible for, these outside websites or their content. Please be aware that the terms of this Privacy Policy do not apply to these outside websites or content, or to any collection of data after you click on links to such outside websites. You may determine whether or not we are responsible for the content of a website by reviewing the URL and confirming the ownership of the applicable domain by means of a service such as DNSstuff.com.

    7.2 Disclosure to Third Party Service Providers.
    Except as otherwise stated in this policy, we do not generally sell, trade, share, or rent the Personal Data collected from our services to other entities. However, we may share your Personal Data with third party service providers to provide you with the Products that we offer you through our website; to process payments; to conduct quality assurance testing; to facilitate creation of accounts; to collect and analyze data; to provide technical support; or to provide specific services, such as synchronization with other software applications. These third party service providers are required not to use your Personal Data other than to provide the services requested by us. You expressly consent to the sharing of your Personal Data with our contractors and other service providers for the purposes listed in this section.

    7.3 Disclosure to Third Party Companies.
    We may enter into agreements with Third Party Companies. A Third Party Company may want access to Personal Data that we collect from our customers. As a result, we may disclose your Personal Data to a Third Party Company; however, we will not disclose your Personal Data to Third Party Companies for the Third Party Companies' own direct marketing purposes, unless you have "opted-in" by following the instructions we provide to allow such disclosure. If you have opted-in to receive e-mail communications from a Third Party Company and later wish to discontinue receipt of these e-mails, please contact the Third Party Company directly to update your preferences. The privacy policies of our Third Party Companies may apply to the use and disclosure of your Personal Data that we collect and disclose to such Third Party Companies. Because we do not control the privacy practices of our Third Party Companies, you should read and understand their privacy policies.

    8. Your Choices Regarding Your Personal Data
    We offer you choices regarding the collection, use, and sharing of your Personal Data. We will periodically send you free newsletters and e-mails that directly promote the use of our site or the purchase of our Products. When you receive newsletters or promotional communications from us, you may indicate a preference to stop receiving further communications from us and you will have the opportunity to "opt-out" by following the unsubscribe instructions provided in the e-mail you receive or by contacting us directly (please see contact information above). Despite your indicated e-mail preferences, we may send you notices of any updates to our Privacy Policy.

    9. Your Legal Rights regarding your Personal Data.
    Under certain circumstances, you have rights under data protection laws in relation to your Personal Data.

    You have the right to:

    Request access to your personal data (commonly known as a “data subject access request”). This enables you to receive a copy of the personal data we hold about you and to check that we are lawfully processing it.

    Request correction of the personal data that we hold about you. This enables you to have any incomplete or inaccurate data we hold about you corrected, though we may need to verify the accuracy of the new data you provide to us.

    Request erasure of your personal data. This enables you to ask us to delete or remove personal data. You also have the right to ask us to delete or remove your personal data where you have successfully exercised your right to object to processing (see below), where we may have processed your information unlawfully or where we are required to erase your personal data to comply with local law. Note, however, that we may not always be able to comply in full with your request of erasure for specific legal reasons which will be notified to you, if applicable, at the time of your request.

    Object to processing of your personal data where we are relying on a legitimate interest (or those of a third party) and there is something about your particular situation which makes you want to object to processing on this ground as you feel it impacts on your fundamental rights and freedoms. You also have the right to object where we are processing your personal data for direct marketing purposes. In some cases, we may demonstrate that we have compelling legitimate grounds to process your information which override your rights and freedoms.

    Request restriction of processing of your personal data. This enables you to ask us to suspend the processing of your personal data in the following scenarios: (a) if you want us to establish the data’s accuracy; (b) where our use of the data is unlawful but you do not want us to erase it; (c) where you need us to hold the data even if we no longer require it as you need it to establish, exercise or defend legal claims; or (d) you have objected to our use of your data but we need to verify whether we have overriding legitimate grounds to use it.

    Request the transfer of your personal data to you or to a third party. We will provide to you, or a third party you have chosen, your personal data in a structured, commonly used, machine-readable format. Note that this right only applies to automated information which you initially provided consent for us to use or where we used the information to perform a contract with you.

    Withdraw consent at any time where we are relying on consent to process your personal data. However, this will not affect the lawfulness of any processing carried out before you withdraw your consent. If you withdraw your consent, we may not be able to provide certain products or services to you. We will advise you if this is the case at the time you withdraw your consent.

    If you wish to exercise any of the above rights please contact privacy@mongodb.com. You will not have to pay a fee to access your personal data (or to exercise any of the other rights). However, we may charge a reasonable fee if your request is clearly unfounded, repetitive or excessive. Alternatively, we may refuse to comply with your request in these circumstances. We may need to request specific information from you to help us confirm your identity and ensure your right to access your personal data (or to exercise any of your other rights). This is a security measure to ensure that personal data is not disclosed to any person who has no right to receive it. We may also contact you to ask you for further information in relation to your request to speed up our response. We try to respond to all legitimate requests within one month. Occasionally it may take us longer than a month if your request is particularly complex or you have made a number of requests. In this case, we will notify you and keep you updated.

    10. Security Of Your Personal Data.
    Unfortunately, the transmission of information via the internet is not completely secure. Although we are committed to protecting your Personal Data, we cannot guarantee the security of your information transmitted to our site; any transmission is at your own risk. Once we have received your information, we use a variety of industry-standard security technologies and procedures to help protect your Personal Data from unauthorized access, use, or disclosure. We also require you to enter a password to access your account information. Please do not disclose your account password to unauthorized people. We have put in place procedures to deal with any suspected personal data breach and will notify you and any applicable regulator of a breach where required to do so.

    11. Data Retention
    We will only retain your Personal Data for as long as necessary to fulfill the purposes we collected it for, including for the purposes of satisfying any legal, accounting, or reporting requirements.

    To determine the appropriate retention period for personal data, we consider the amount, nature, and sensitivity of the personal data, the potential risk of harm from unauthorised use or disclosure of your personal data, the purposes for which we process your personal data and whether we can achieve those purposes through other means, and the applicable legal requirements.

    12. Dispute Resolution.
    If you believe that we have not adhered to this Privacy Policy, please contact us by e-mail at legal@mongodb.com. We will do our best to address your concerns. If you feel that your complaint has been addressed incompletely, we invite you to let us know for further investigation. If we are unable to reach a resolution to the dispute, we will settle the dispute exclusively under the rules of the American Arbitration Association.

    13. Changes To This Privacy Policy.
    This Privacy Policy is subject to occasional revision, and if we make any substantial changes in the way we use your Personal Data, we will notify you by sending you an e-mail to the last e-mail address you provided to us or by prominently posting notice of the changes on our website. Any material changes to this Privacy Policy will be effective upon the earlier of thirty (30) calendar days following our dispatch of an e-mail notice to you or thirty (30) calendar days following our posting of notice of the changes on our site. These changes will be effective immediately for new users of our website and Products. Please note that at all times you are responsible for updating your Personal Data to provide us with your most current e-mail address. In the event that the last e-mail address that you have provided us is not valid, or for any reason is not capable of delivering to you the notice described above, our dispatch of the e-mail containing such notice will nonetheless constitute effective notice of the changes described in the notice. In any event, changes to this Privacy Policy may affect our use of Personal Data that you provided us prior to our notification to you of the changes. If you do not wish to permit changes in our use of your Personal Data, you must notify us prior to the effective date of the changes that you wish to deactivate your account with us. Continued use of our website or Products, following notice of such changes shall indicate your acknowledgement of such changes and agreement to be bound by the terms and conditions of such changes.

    14. Transfers of Personal Data outside the EEA.
    Your Personal Data may be processed in the country in which it was collected and in other countries, including the United States, where laws regarding processing of Personal Data may be less stringent than the laws in your country. MongoDB complies with the EU-U.S. Privacy Shield Framework and Swiss-U.S. Privacy Shield Framework (collectively, "Privacy Shield") as set forth by the U.S. Department of Commerce regarding the collection, use, and retention of personal information transferred from the European Union, Switzerland, and the United Kingdom to the United States in reliance on Privacy Shield. MongoDB has certified to the Department of Commerce that it adheres to the Privacy Shield Principles with respect to such information. If there is any conflict between the terms in this Privacy Policy and the Privacy Shield Principles, the Privacy Shield Principles shall govern. To learn more about the Privacy Shield program, and to view our certification, please visit https://www.privacyshield.gov/.

    You may direct any inquiries or complaints concerning our Privacy Shield compliance to privacy@mongodb.com. MongoDB will respond within 45 days. If we fail to respond within that time, or if our response does not address your concern, you may contact the International Centre for Dispute Resolution, the international division of the American Arbitration Association (ICDR/AAA), which provides an independent third-party dispute resolution body based in the United States, here. ICDR/AAA has committed to respond to complaints and to provide appropriate recourse at no cost to you. If neither MongoDB nor ICDR/AAA resolves your complaint, you may have the possibility to engage in binding arbitration through the Privacy Shield Panel.

    As noted above, MongoDB uses a limited number of third-party service providers to assist us in providing our services to customers. These third parties may access, process, or store personal data in the course of providing their services. MongoDB maintains contracts with these third parties restricting their access, use and disclosure of personal data in compliance with our Privacy Shield obligations, and MongoDB may be liable if they fail to meet those obligations and we are responsible for the event giving rise to the damage.

    MongoDB’s commitments under the Privacy Shield are subject to the investigatory and enforcement powers of the United States Federal Trade Commission. MongoDB may be required to disclose personal information in response to lawful requests by public authorities, including to meet national security or law enforcement requirements.

    This Privacy Policy was last revised on 29 March 2019.
    """
    
    @IBOutlet weak var startDrawingButton: UIButton! // APPENG-72
    @IBOutlet weak var agreedToTermsButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
    
    @IBAction func enteringEmailField(_ sender: UITextField) {
        isValidEmail(emailStr: emailField.text ?? "")
    }
    
    @IBAction func showTermsAndConditionsButton() {
        let alert = UIAlertController(title: "Terms & Conditions and Privacy Policy", message: termsConditionsPrivacyPolicy, preferredStyle: UIAlertController.Style.alert)
        // add an action (button)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    func configDrawingButton() {
        startDrawingButton.backgroundColor = (agreedToTerms && gotValidEmail)
                  ? UIColor.green : UIColor.lightGray// APPENG-72
               startDrawingButton.isEnabled = (agreedToTerms && gotValidEmail) ? true : false
    }
    func isValidEmail(emailStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        gotValidEmail = emailPred.evaluate(with: emailStr)
      configDrawingButton()
        return gotValidEmail  // APPENG-72
    }
    @IBAction func agreeToTermsButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        agreedToTerms = sender.isSelected
        configDrawingButton()
    }

  @IBAction func startDrawingPressed(_ sender: Any) {
        if !isValidEmail(emailStr: emailField.text ?? "") {
            // create the alert
            let alert = UIAlertController(title: "Ooops!", message: "Please enter a valid email", preferredStyle: UIAlertController.Style.alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
            return
        } else if !agreedToTerms {
            // create the alert
            let alert = UIAlertController(title: "Ooops!", message: "You must agree to the Terms & Conditions", preferredStyle: UIAlertController.Style.alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
            return
        }
        User.email = emailField.text!
        emailField.text = ""
        emailField.endEditing(true)
        agreedToTerms = false
        agreedToTermsButton.isSelected = false
        
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DrawViewController") as? DrawViewController
        self.navigationController!.pushViewController(vc!, animated: true)

    }
    // TODO Remove?
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "startDrawingSegue" { // you define it in the storyboard (click on the segue, then Attributes' inspector > Identifier
            
            if !isValidEmail(emailStr: emailField.text ?? "") {
                // create the alert
                let alert = UIAlertController(title: "Ooops!", message: "Please enter a valid email", preferredStyle: UIAlertController.Style.alert)
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
                return false
            } else if !agreedToTerms {
                // create the alert
                let alert = UIAlertController(title: "Ooops!", message: "You must agree to the Terms & Conditions", preferredStyle: UIAlertController.Style.alert)
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
                return false
            }
            else {
                return true
            }
        }
        return true
    }
}
