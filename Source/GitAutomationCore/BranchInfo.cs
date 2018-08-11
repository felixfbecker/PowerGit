// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//   
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using System.Collections.Generic;
using System.Linq;
using LibGit2Sharp;

namespace GitAutomationCore
{
    public sealed class BranchInfo
    {
        public BranchInfo(Branch branch)
        {
            Name = branch.FriendlyName;
            CanonicalName = branch.CanonicalName;
            UpstreamBranchCanonicalName = branch.UpstreamBranchCanonicalName;
            IsRemote = branch.IsRemote;
            IsTracking = branch.IsTracking;
            IsCurrentRepositoryHead = branch.IsCurrentRepositoryHead;
            Tip = new CommitInfo(branch.Tip);
        }

        public string Name { get; private set; }
        public string CanonicalName { get; private set; }
        public string UpstreamBranchCanonicalName { get; private set; }
        public bool IsRemote { get; private set; }
        public bool IsTracking { get; private set; }
        public bool IsCurrentRepositoryHead { get; private set; }
        public CommitInfo Tip { get; private set; }
    }
}
