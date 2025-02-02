# TerminalAI

TerminalAI is a PowerShell-based interactive terminal that integrates with the Gemini API to provide AI-powered responses to user queries. It also includes basic terminal commands and customizable configurations.

## Features

- **Basic Terminal Commands**: Execute common terminal commands like `ls`, `pwd`, `cd`, `mkdir`, and `exit`.
- **AI Integration**: Use the `!<query>` syntax to send queries to the Gemini API and receive AI-generated responses.
- **Customizable Configuration**: Modify the appearance and behavior of the terminal through the `config.json` file.
- **Help Functionality**: Display a help menu with the `help` command.

## Setup

1. **Clone the repository**:
    ```sh
    git clone https://github.com/Andru0Gx/TerminalAI.git
    cd TerminalAI
    ```

2. **Configure Environment Variables**:
    - Create a [.env](./.env.demo) file in the root directory with the following content:
        ```bash
        GEMINI_API_KEY = "YOUR-GEMINI-API-KEY"
        ```

3. **Configure Settings**:
    - Modify the [config.json](config.json) file to customize the terminal's appearance and behavior.

## Usage

1. **Run the Terminal**:
    - Open PowerShell and navigate to the project directory.
    - Execute the [Terminal-AI.ps1](./Terminal-AI.ps1) script:
        ```powershell
        .\AI.ps1
        ```

2. **Basic Commands**:
    - Use standard terminal commands like `ls`, `pwd`, `cd`, `mkdir`, and `exit`.

3. **AI Queries**:
    - Use the `!<query>` syntax to send queries to the Gemini API. For example:
        ```sh
        !What is the weather today?
        ```

4. **Help**:
    - Display the help menu with the `help` command.

## Configuration

The [config.json](./config.json) file allows you to customize various aspects of the terminal:

- `truncate_path_folders`: Number of folders to display in the truncated path.
- `separator`: Separator between the path and the input prompt.
- `path_color`: Color of the path.
- `separator_color`: Color of the separator.
- `HelpTitleColor`: Color of the help title.
- `HelpSubTitleColor`: Color of the help subtitles.
- `HelpCommandColor`: Color of the help commands.
- `ErrorColor`: Color of error messages.
- `AITittle`: Color of the AI title.
- `AIContent`: Color of the AI content.
- `hint_enabled`: Enable or disable the hint message at startup.

## Run on Terminal Startup

To run the script by default when starting the terminal, follow these steps:

1. Open your PowerShell profile script. You can find the profile path by running:
    ```powershell
    $PROFILE
    ```

2. Open the profile script in a text editor. If the file does not exist, create it:
    ```powershell
    notepad $PROFILE
    ```

3. Add the following line to the profile script to run the [Terminal-AI.ps1](./Terminal-AI.ps1) script on startup:
    ```powershell
    . "C:\Path\To\Your\Project\AI.ps1"
    ```

4. Save and close the profile script.


## License

This project is licensed under the MIT License.