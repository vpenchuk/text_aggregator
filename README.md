# text_aggregator
Aggregate the contents of a list of specified files in a single output file. Separates aggregated text with "//..path_to_file"

This is a simple bash script to aggregate the contents of multiple files into a single file called "aggregate.txt". It is useful for combining the contents of multiple files into a single file while preserving the original files. The script also adds the file path/name as a comment at the beginning of each file's content and adds three new lines between each file's content for better readability.

## Usage

1. Open the script in a text editor and modify the `files` array to include the file paths/names you want to aggregate.

   Example:

   ```bash
   files=(
     "path/to/first-file.js"
     "path/to/second-file.css"
     "path/to/third-file.html"
   )
   ```

2. Save the script and run it in your terminal:

   ```bash
   ./aggregate_files.sh
   ```

3. The script will create a new file called "aggregate.txt" in the current directory, containing the combined contents of the specified files. If the file already exists, it will be overwritten.

   Example output:

   ```
   //path/to/first-file.js
   content of first-file.js


   //path/to/second-file.css
   content of second-file.css


   //path/to/third-file.html
   content of third-file.html
   ```

## Error Handling

If a specified file is not found, the script will display an error message and continue processing the remaining files.

Example:

```
Error: path/to/non-existent-file.js not found.
```

## Customizing the Output

You can change the output file name by modifying the `aggregate` variable:

```bash
aggregate="your_custom_output_file_name.txt"
```

You can also change the number of new lines between each file's content by modifying the `echo -e "\n\n\n"` line:

```bash
echo -e "\n\n" >> "$aggregate" # Add two new lines instead of three
```