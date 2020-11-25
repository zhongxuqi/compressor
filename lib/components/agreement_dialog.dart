import 'package:flutter/material.dart';
import '../localization/localization.dart';

void showAgreementDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        contentPadding: EdgeInsets.all(0),
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height / 2,
            padding: EdgeInsets.only(top: 8, left: 8, right: 8),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      Text("""    本应用尊重并保护所有使用服务用户的个人隐私权。为了给您提供更准确、更有个性化的服务，本应用会按照本隐私权政策的规定使用和披露您的个人信息。但本应用将以高度的勤勉、审慎义务对待这些信息。除本隐私权政策另有规定外，除本隐私政策相关有规定外在未得到您允许 的情况下，本应用不会将这些信息向第三放提供在未征得您事先许可的情况下，本应用不会将这些信息对外披露或向第三方提供。本应用会不时更新本隐私权政策。 您在同意本应用服务使用协议之时，即视为您已经同意本隐私权政策全部内容。本隐私权政策属于本应用服务使用协议不可分割的一部分。

1. 适用范围

    在您注册本应用帐号时，您根据本应用要求提供的个人注册信息；
    在您使用本应用网络服务，或访问本应用平台网页时，本应用自动接收并记录的您的浏览器和计算机上的信息，包括但不限于您的IP地址、浏览器的类型、使用的语言、访问日期和时间、软硬件特征信息及您需求的网页记录等数据；
    本应用通过合法途径从商业伙伴处取得的用户个人数据。
    您了解并同意，以下信息不适用本隐私权政策：
    ①您在使用本应用平台提供的搜索服务时输入的关键字信息；
    ②本应用收集到的您在本应用发布的有关信息数据，包括但不限于参与活动、成交信息及评价详情；
    ③违反法律规定或违反本应用规则行为及本应用已对您采取的措施。

2. 信息使用

    本应用不会向任何无关第三方提供、出售、出租、分享或交易您的个人信息，除非事先得到您的许可，或该第三方和本应用（含本应用关联公司）单独或共同为您提供服务，且在该服务结束后，其将被禁止访问包括其以前能够访问的所有这些资料。
    本应用亦不允许任何第三方以任何手段收集、编辑、出售或者无偿传播您的个人信息。任何本应用平台用户如从事上述活动，一经发现，本应用有权立即终止与该用户的服务协议。
    为服务用户的目的，本应用可能通过使用您的个人信息，向您提供您感兴趣的信息，包括但不限于向您发出产品和服务信息，或者与本应用合作伙伴共享信息以便他们向您发送有关其产品和服务的信息（后者需要您的事先同意）。

3. 信息披露

    在如下情况下，本应用将依据您的个人意愿或法律的规定全部或部分的披露您的个人信息：
    经您事先同意，向第三方披露；
    为提供您所要求的产品和服务，而必须和第三方分享您的个人信息；
    根据法律的有关规定，或者行政或司法机构的要求，向第三方或者行政、司法机构披露；
    如您出现违反中国有关法律、法规或者本应用服务协议或相关规则的情况，需要向第三方披露；
    如您是适格的知识产权投诉人并已提起投诉，应被投诉人要求，向被投诉人披露，以便双方处理可能的权利纠纷；
    在本应用平台上创建的某一交易中，如交易任何一方履行或部分履行了交易义务并提出信息披露请求的，本应用有权决定向该用户提供其交易对方的联络方式等必要信息，以促成交易的完成或纠纷的解决。
    其它本应用根据法律、法规或者网站政策认为合适的披露。

4. 信息存储和交换

    本应用收集的有关您的信息和资料将保存在本应用及（或）其关联公司的服务器上，这些信息和资料可能传送至您所在国家、地区或本应用收集信息和资料所在地的境外并在境外被访问、存储和展示。

5. Cookie的使用

    在您未拒绝接受cookies的情况下，本应用会在您的计算机上设定或取用cookies ，以便您能登录或使用依赖于cookies的本应用平台服务或功能。本应用使用cookies可为您提供更加周到的个性化服务，包括推广服务。
    您有权选择接受或拒绝接受cookies。您可以通过修改浏览器设置的方式拒绝接受cookies。但如果您选择拒绝接受cookies，则您可能无法登录或使用依赖于cookies的本应用网络服务或功能。
    通过本应用所设cookies所取得的有关信息，将适用本政策

6. 信息安全

    本应用帐号均有安全保护功能，请妥善保管您的用户名及密码信息。本应用将通过对用户密码进行加密等安全措施确保您的信息不丢失，不被滥用和变造。尽管有前述安全措施，但同时也请您注意在信息网络上不存在“完善的安全措施”。
    在使用本应用网络服务进行网上交易时，您不可避免的要向交易对方或潜在的交易对

7.本隐私政策的更改

    如果决定更改隐私政策，我们会在本政策中、本公司网站中以及我们认为适当的位置发布这些更改，以便您了解我们如何收集、使用您的个人信息，哪些人可以访问这些信息，以及在什么情况下我们会透露这些信息。
    本公司保留随时修改本政策的权利，因此请经常查看。如对本政策作出重大更改，本公司会通过网站通知的形式告知。

8.儿童隐私相关

    我们注重儿童的隐私。虽然我们的应用程序可供儿童使用，但是只有家长和/或法定监护人或其他成人可以购买商品。若要设置您的机器人，家长或监护人应下载应用程序。产品使用信息仅用于支持我们的内部运营。
    我们不会有意收集或征求 13 岁以下的任何人的个人信息。
    在进行适当的身份验证后，家长或法定监护人可以查看我们收集的关于儿童的信息，要求删除或拒绝允许进一步收集或使用这些信息。请记住，删除这些信息的请求可能会限制儿童访问所有或部分服务。

9.知识产权相关

    您了解并同意我方有权随时检查您所上传或发布的内容，如果发现您上传的内容不符合前述规定，我方有权删除或重新编辑或修改您所上传或发布的内容，且有权在不事先通知您的情况下停用您的账号。您亦了解、同意并保证，您所上传或发布的内容符合前述规定，是您的义务，而非我方，我方无任何对您上传或发布的内容进行主动检查、编辑或修改的义务。
    若您在本软件上的上传或发布内容的行为给第三方带来损害或损失，第三方主张赔偿或衍生的任何其他权利的，由您独立承担全部法律责任，我方及合作方概不承担任何责任。
    我方不对用户上传或发布的内容的合法性、正当性、完整性或品质作出任何保证，用户需自行承担因使用或依赖由软件所传送的内容或资源所产生的风险，我方在任何情况下对此种风险可能或实际带来的损失或损害都不负任何责任。

10.法律责任与免责申明

    我方将会尽其商业上的合理努力以保护用户的设备资源及通讯的隐私性和完整性，但是，用户承认和同意我方不能就此事提供任何保证。
    我方可以根据用户的使用状态和行为，为了改进软件的功能、用户体验和服务，开发或调整软件功能
    我方为保障业务发展和调整的自主权，有权随时自行修改或中断软件服务而无需通知用户。
    在任何情况下用户因使用或不能使用本软件所产生的直接、间接、偶然、特殊及后续的损害及风险，我方及合作方不承担任何责任。
    因技术故障等不可抗事件影响到服务的正常运行的，我方及合作方承诺在第一时间内与相关单位配合，及时处理进行修复，但用户因此而遭受的一切损失，我方及合作方不承担责任。
    用户通过软件与其他用户联系，因受误导或欺骗而导致或可能导致的任何心理、生理上的伤害以及经济上的损失，由过错方依法承担所有责任，一概与我方及合作方无关。
""",
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              RawMaterialButton(
                child: Text(
                  AppLocalizations.of(context).getLanguageText('read'),
                  style: TextStyle(
                    color: Colors.green,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      );
    },
  );
}