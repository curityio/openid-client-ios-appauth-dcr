//
// Copyright (C) 2021 Curity AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct RegistrationView: View {
    
    @ObservedObject private var model: RegistrationViewModel
    
    init(model: RegistrationViewModel) {
        self.model = model
    }
    
    var body: some View {

        let isEnabled = self.model.isLoaded
        return VStack {

            if self.model.error != nil {
                ErrorView(model: ErrorViewModel(error: self.model.error!))
            }

            Text("unregistered_message")
                .labelStyle()
                .padding(.top, 20)

            Image("StartIllustration")
                .aspectRatio(contentMode: .fit)
                .padding(.top, 20)

            Button(action: self.model.startRegistration) {
               Text("start_registration")
            }
            .padding(.top, 20)
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .buttonStyle(CustomButtonStyle(disabled: !isEnabled))
            .disabled(!isEnabled)

            Spacer()
        }
        .onAppear(perform: self.onViewCreated)
    }
    
    func onViewCreated() {
    }
}
