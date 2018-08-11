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

using System.Collections;
using System.Collections.Generic;

namespace GitAutomationCore
{
    public sealed class SendBranchResult : IEnumerable
    {
        public SendBranchResult()
        {
            MergeResult = new List<LibGit2Sharp.MergeResult>();
            PushResult = new List<PushResult>();
        }

        public LibGit2Sharp.MergeResult LastMergeResult { get { return MergeResult[MergeResult.Count - 1]; } }

        public PushResult LastPushResult { get { return PushResult[PushResult.Count - 1]; } }

        public List<LibGit2Sharp.MergeResult> MergeResult { get; private set; }

        public List<PushResult> PushResult { get; private set; }

        public IEnumerator GetEnumerator()
        {

            var maxIdx = MergeResult.Count;
            if (PushResult.Count > maxIdx)
                maxIdx = PushResult.Count;

            var results = new ArrayList(MergeResult.Count + PushResult.Count);

            for (int idx = 0; idx < maxIdx; ++idx)
            {
                if (MergeResult.Count < idx)
                {
                    results.Add(MergeResult[idx]);
                }

                if (PushResult.Count < idx)
                {
                    results.Add(PushResult[idx]);
                }
            }

            return results.GetEnumerator();
        }
    }
}
