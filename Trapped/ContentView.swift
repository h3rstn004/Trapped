import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var game = GameCoordinator()

    var body: some View {
        ZStack {
            RealityView { content in
                content.camera = .virtual
                game.start(in: content)
            }
            .ignoresSafeArea()

            GameOverlay(game: game)
        }
        .background(Color.black)
    }
}

@MainActor
final class GameCoordinator {
    let input = InputController()
    let player: PlayerController

    private var hasStarted = false
    private var updateSubscription: EventSubscription?

    init() {
        player = PlayerController(input: input)
    }

    func start(in content: RealityViewCameraContent) {
        guard !hasStarted else { return }
        hasStarted = true

        let room = RoomBuilder.makeRoom()
        room.addChild(player.player)
        content.add(room)

        updateSubscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.player.update(deltaTime: event.deltaTime)
        }
    }

    func setMovement(_ value: SIMD2<Float>) {
        input.setMovement(value)
    }

    func addLookDelta(_ value: SIMD2<Float>) {
        input.addLookDelta(value)
    }

    func toggleFlashlight() {
        player.flashlight.toggle()
    }

    var flashlightIsOn: Bool {
        player.flashlight.isOn
    }
}

struct GameOverlay: View {
    let game: GameCoordinator
    @State private var flashlightIsOn = false

    var body: some View {
        ZStack {
            #if os(iOS)
            VStack {
                Spacer()

                HStack(alignment: .bottom) {
                    VirtualJoystick { value in
                        game.setMovement(value)
                    }

                    Spacer()

                    Button {
                        game.toggleFlashlight()
                        flashlightIsOn = game.flashlightIsOn
                    } label: {
                        Image(systemName: flashlightIsOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(.black.opacity(0.55), in: Circle())
                    }
                    .accessibilityLabel("Toggle flashlight")
                    .padding(.trailing, 24)
                }
                .padding(.bottom, 24)
            }
            .allowsHitTesting(true)
            .zIndex(1)

            TouchLookArea { delta in
                game.addLookDelta(delta)
            }
            .ignoresSafeArea()
            .allowsHitTesting(true)
            .zIndex(0)
            #elseif os(macOS)
            MacKeyboardInputView(game: game)
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)

            VStack {
                HStack {
                    Spacer()
                    Text("WASD move • drag mouse to look • F flashlight")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(10)
                }
                Spacer()
            }
            #endif
        }
    }
}

#if os(iOS)
private struct VirtualJoystick: View {
    let onChange: (SIMD2<Float>) -> Void

    private let radius: CGFloat = 58
    @State private var thumbOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.45))
                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(.white.opacity(0.75))
                .frame(width: 48, height: 48)
                .offset(thumbOffset)
        }
        .frame(width: radius * 2, height: radius * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let distance = hypot(value.translation.width, value.translation.height)
                    let limit = radius - 24
                    let scale = min(1, limit / max(distance, 0.001))
                    let offset = CGSize(
                        width: value.translation.width * scale,
                        height: value.translation.height * scale
                    )
                    thumbOffset = offset

                    let normalized = SIMD2<Float>(
                        Float(offset.width / limit),
                        Float(-offset.height / limit)
                    )
                    onChange(normalized)
                }
                .onEnded { _ in
                    thumbOffset = .zero
                    onChange(.zero)
                }
        )
        .accessibilityLabel("Movement joystick")
    }
}

private struct TouchLookArea: View {
    let onDelta: (SIMD2<Float>) -> Void

    @State private var lastTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .frame(width: proxy.size.width * 0.65)
                .frame(maxHeight: .infinity)
                .position(
                    x: proxy.size.width * 0.675,
                    y: proxy.size.height / 2
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let delta = SIMD2<Float>(
                                Float(value.translation.width - lastTranslation.width),
                                Float(value.translation.height - lastTranslation.height)
                            )
                            lastTranslation = value.translation
                            onDelta(delta)
                        }
                        .onEnded { _ in
                            lastTranslation = .zero
                        }
                )
        }
        .allowsHitTesting(true)
    }
}
#endif

#if os(macOS)
import AppKit

private struct MacKeyboardInputView: NSViewRepresentable {
    let game: GameCoordinator

    func makeNSView(context: Context) -> InputNSView {
        let view = InputNSView()
        view.game = game
        return view
    }

    func updateNSView(_ nsView: InputNSView, context: Context) {
        nsView.game = game
    }
}

private final class InputNSView: NSView {
    weak var game: GameCoordinator?
    private var pressedKeys = Set<UInt16>()

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        pressedKeys.insert(event.keyCode)

        if event.keyCode == 3 { // F
            game?.toggleFlashlight()
        }

        updateMovement()
    }

    override func keyUp(with event: NSEvent) {
        pressedKeys.remove(event.keyCode)
        updateMovement()
    }

    override func mouseDragged(with event: NSEvent) {
        game?.addLookDelta(
            SIMD2<Float>(Float(event.deltaX), Float(event.deltaY))
        )
    }

    private func updateMovement() {
        let x = (pressedKeys.contains(2) ? 1 : 0) - (pressedKeys.contains(0) ? 1 : 0)
        let y = (pressedKeys.contains(13) ? 1 : 0) - (pressedKeys.contains(1) ? 1 : 0)
        game?.setMovement(SIMD2<Float>(Float(x), Float(y)))
    }
}
#endif
