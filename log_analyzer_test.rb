require './git_jenkins_remote_trigger'

include LogAnalyzer

logs = %Q{
commit 90fee7075e7e33b48b54eb92165a105de16b77cf
Author: christian.chen@quest.com <christian.chen@quest.com>
Date:   Sat Mar 31 09:43:53 2012 +0800

    [master] [FGLEU-2444] [Rabbit] Finished "Delete Special Event"
    [master] [FGLEU-2561] [Rabbit] Resolved
    [master] [FGLEU-2642] [Rabbit] Resolved
    [master] [FGLEU-2001] [Christian] Modified scope radio list in custom field dialogue & related functions.
    [master] [FGLEU-2565] [Nacy] Begin working on Session Explorer - Detial Views.

commit 4bb306a57a7a553d1f86342aa4f738c49535b485
Author: Bill Wixted <bill.wixted@quest.com>
Date:   Fri Mar 30 11:38:54 2012 -0700

    [master][FGLEU-2001] clarified scope options

commit b5169a763238bbe164b7129e02c1181fc02cb1ad
Author: Bill Wixted <bill.wixted@quest.com>
Date:   Fri Mar 30 10:31:48 2012 -0700

    [master][FGLEU-2554] added label to Sequence Analyzer Event wireframe
}

puts analyze_multiple_commit_logs(logs)
