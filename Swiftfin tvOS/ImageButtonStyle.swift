struct ImageButtonStyle: ButtonStyle {

    let focused: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(6)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .cornerRadius(100)
            .shadow(color: .black, radius: self.focused ? 20 : 0, x: 0, y: 0) //  0

    }
}
