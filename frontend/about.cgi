#!/usr/bin/ruby
#File: about.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus

#   This is the about page for Icarus

$stdout.sync = true
$stderr.reopen $stdout

print "Content-type: text/html\n\n"

require 'cgi'

cgi = CGI.new("html5")
usrName = cgi['usrName'].to_s.strip
envLoaderCode = File.read(File.expand_path('../env_loader.rb', __dir__))
workflowCode = File.read(File.expand_path('../.github/workflows/publish.yml', __dir__))
signInFlowCode = <<~'RUBY'
    if cgi.request_method == 'POST'
        if usrName.empty? || password.empty?
            errorMessage = 'Please fill out username and password.'
        elsif signIn(usrName, password, db)
            puts "<!DOCTYPE html>"
            puts "<html>"
            puts "  <head>"
            puts "    <title>Redirecting...</title>"
            puts "  </head>"
            puts "  <body onload=\"document.getElementById('accountPostForm').submit();\">"
            puts "    <form id=\"accountPostForm\" method=\"post\" action=\"account.cgi\">"
            puts "      <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
            puts "    </form>"
            puts "    <noscript>"
            puts "      <button type=\"submit\" form=\"accountPostForm\">Continue to account</button>"
            puts "    </noscript>"
            puts "  </body>"
            puts "</html>"
            exit
        else
            errorMessage = 'Incorrect username or password.'
            usrName = ''
        end
    end
RUBY

navBar = <<~'RUBY'
    puts "                <li>"
    puts "                    <form class=\"nav-post-form\" action=\"readingLog.cgi\" method=\"POST\">"
    puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "                        <button type=\"submit\" class=\"nav-post-button\">Reading Log</button>"
    puts "                    </form>"
    puts "                </li>"
RUBY

notes = <<~'RUBY'
    if cgi['note'] != ""
        createNote(userId, bookId, cgi['note'], db) if !userId.nil?
        puts "<!DOCTYPE html>"
        puts "<html>"
        puts "  <head>"
        puts "    <title>Redirecting...</title>"
        puts "  </head>"
        puts "  <body onload=\"document.getElementById('autoSubmitForm').submit();\">"
        puts "<form id=\"autoSubmitForm\" action=\"book.cgi\" method=\"POST\" style=\"display:none;\">"
        puts "    <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
        puts "    <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
        puts "</form>"
        puts "    <noscript>"
        puts "      <button type=\"submit\" form=\"autoSubmitForm\">Continue to book</button>"
        puts "    </noscript>"
        puts "  </body>"
        puts "</html>"
        exit
    end
RUBY

readingLogBookActionsCode = <<~'RUBY'
    if usrName != ""
        if inReadingLog
            puts "                      <form class=\"signin-form book-note-form\" action=\"book.cgi\" method=\"POST\">"
            puts "                          <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
            puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
            puts "                          <input type=\"hidden\" name=\"deleteLogEntry\" value=\"true\">"
            puts "                          <input type=\"submit\" class=\"signin-submit\" value=\"Remove From Reading Log\">"
            puts "                      </form>"
        else
            puts "                      <form class=\"signin-form book-note-form\" action=\"book.cgi\" method=\"POST\">"
            puts "                          <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
            puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
            puts "                          <input type=\"hidden\" name=\"addingToLog\" value=\"true\">"
            puts "                          <input type=\"submit\" class=\"signin-submit\" value=\"Add To Reading Log\">"
            puts "                      </form>"
        end
    end
RUBY

readingLogPageCode = <<~'RUBY'
    if removeFromLog
        db.query("DELETE FROM ReadingLog WHERE usr_id = #{user['usr_id'].to_i} AND book_id = #{removeBookId};")
    end

    if searchQuery == ''
        readingLogQuery = db.query("SELECT b.* FROM ReadingLog rl JOIN Books b ON rl.book_id = b.book_id WHERE rl.usr_id = #{user['usr_id'].to_i} ORDER BY b.title ASC;")
    else
        searchLike = db.escape("%#{searchQuery}%")
        readingLogQuery = db.query("SELECT b.* FROM ReadingLog rl JOIN Books b ON rl.book_id = b.book_id WHERE rl.usr_id = #{user['usr_id'].to_i} AND (b.title LIKE '#{searchLike}') ORDER BY b.title ASC;")
    end

    puts "                        <form class=\"signin-form book-note-form\" action=\"readingLog.cgi\" method=\"POST\">"
    puts "                            <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "                            <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
    puts "                            <input type=\"hidden\" name=\"removeFromLog\" value=\"true\">"
    puts "                            <input type=\"submit\" class=\"signin-submit\" value=\"Remove From Reading Log\">"
    puts "                        </form>"
RUBY

searchPageCode = <<~'RUBY'
        searchResponse = cgi['searchType']
        searchType = searchResponse == '' ? 'books' : searchResponse
        searchQuery = cgi['searchQuery'] || ''
        searchResults = []
        searchPlaceholder = searchType == 'books' ? 'Search for books...' : 'Search for authors...'

        if searchQuery && !searchQuery.empty?
            if searchType == 'authors'
                searchResults = findAuthors(db, searchQuery).to_a
            else
                searchResults = findBooks(db, searchQuery).to_a
            end
        end

        puts "            <form action=\"search.cgi\" method=\"POST\" class=\"search-form\">"
        puts "                <input type=\"hidden\" name=\"searchType\" value=\"#{searchType}\">"
        puts "                <input type=\"text\" name=\"searchQuery\" class=\"search-input\" maxlength=\"255\" placeholder=\"#{searchPlaceholder}\" value=\"#{searchQuery}\">"
        puts "                <button type=\"submit\" class=\"search-button\">Search</button>"
        puts "            </form>"
RUBY

searchBackendCode = <<~'RUBY'
        def findBooks(db, userString)
                return db.query("SELECT * FROM Books WHERE title LIKE '%" + userString.to_s().gsub("'", "''").strip + "%';")
        end

        def findAuthors(db, userString)
                return db.query("SELECT * FROM Authors WHERE name LIKE '%" + userString.to_s().gsub("'", "''").strip + "%';")
        end
RUBY

icon = <<~'RUBY'
    <script>
        function updateFavicon() {
            const favicon = document.getElementById('favicon');
            const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            favicon.href = isDark ? '../faviconwhite.ico' : '../favicon.ico';
        }
        updateFavicon();
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', updateFavicon);
    </script>
RUBY

puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>About</title>"
puts "        <link rel=\"icon\" type=\"image/x-icon\" href=\"../favicon.ico\" id=\"favicon\" />"
puts "        <link rel=\"stylesheet\" href=\"../Icarus.css\">"
puts "        <script>"
puts "            function updateFavicon() {"
puts "                const favicon = document.getElementById('favicon');"
puts "                const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;"
puts "                favicon.href = isDark ? '../faviconwhite.ico' : '../favicon.ico';"
puts "            }"
puts "            updateFavicon();"
puts "            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', updateFavicon);"
puts "        </script>"
puts "    </head>"
puts "    <body>"
if usrName == ""
    puts "        <nav>"
    puts "            <nav><a class=\"logo\" href=../index.cgi>Icarus</a></nav>"
    puts "            <ul class=\"nav-links\">"
    puts "                <li><a href=../index.cgi>Top Books</a></li>"
    puts "                <li><a href=\"search.cgi\">Search</a></li>"
    puts "                <li><a href=\"readingLog.cgi\">Reading Log</a></li>"
    puts "                <li><a href=\"signIn.cgi\">Sign In</a></li>"
    puts "            </ul>"
    puts "        </nav>"
else
    puts "        <nav>"
    puts "            <nav><form class=\"nav-post-form\" action=\"../index.cgi\" method=\"POST\"><input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\"><button type=\"submit\" class=\"nav-logo-button\">Icarus</button></form></nav>"
    puts "            <ul class=\"nav-links\">"
    puts "                <li>"
    puts "                    <form class=\"nav-post-form\" action=\"../index.cgi\" method=\"POST\">"
    puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "                        <button type=\"submit\" class=\"nav-post-button\">Top Books</button>"
    puts "                    </form>"
    puts "                </li>"
    puts "                <li>"
    puts "                    <form class=\"nav-post-form\" action=\"search.cgi\" method=\"POST\">"
    puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "                        <button type=\"submit\" class=\"nav-post-button\">Search</button>"
    puts "                    </form>"
    puts "                </li>"
    puts "                <li>"
    puts "                    <form class=\"nav-post-form\" action=\"readingLog.cgi\" method=\"POST\">"
    puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "                        <button type=\"submit\" class=\"nav-post-button\">Reading Log</button>"
    puts "                    </form>"
    puts "                </li>"
    puts "                <li>"
    puts "                    <form class=\"nav-post-form\" action=\"account.cgi\" method=\"POST\">"
    puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "                        <button type=\"submit\" class=\"nav-post-button\">#{CGI.escapeHTML(usrName)}</button>"
    puts "                    </form>"
    puts "                </li>"
    puts "            </ul>"
    puts "        </nav>"
end

puts "        <div class=\"about-layout\">"
puts "            <aside class=\"about-sidebar\">"
puts "                <table class=\"about-menu-table\">"
puts "                    <tr><td><a href=\"#env-var-setup\">.env Var Setup</a></td></tr>"
puts "                    <tr><td><a href=\"#ci-cd\">Runner and CI/CD Workflow</a></td></tr>"
puts "                    <tr><td><a href=\"#sign-in-flow\">Sign In and Nav Flow</a></td></tr>"
puts "                    <tr><td><a href=\"#notes\">Notes</a></td></tr>"
puts "                    <tr><td><a href=\"#reading-log\">Reading Log</a></td></tr>"
puts "                    <tr><td><a href=\"#search\">Search</a></td></tr>"
puts "                    <tr><td><a href=\"#icon\">Icon</a></td></tr>"
puts "                    <tr><td><a href=\"#unit-tests\">Unit Tests</a></td></tr>"
puts "                    <tr><td><a href=\"#our-paper\">Paper</a></td></tr>"
puts "                </table>"
puts "            </aside>"

puts "            <main class=\"about-main\">"

puts "                <section id=\"env-var-setup\" class=\"about-section\">"
puts "                    <h1>ENV Var Setup</h1>"
puts "                    <p class=\"about-copy\">To set the project up on a machine, the repo needs to live under a web server that can execute Ruby CGI scripts and connect to the MySQL database used by the site. The application reads ICARUS_DB_HOST, ICARUS_DB_USER, ICARUS_DB_PASSWORD, and ICARUS_DB_NAME from the environment, and env_loader.rb can load those values from a local .env file during development.</p>"
puts "                    <pre class=\"about-code\" data-file=\"env_loader.rb\"><code>#{CGI.escapeHTML(envLoaderCode)}</code></pre>"
puts "                    <p class=\"about-copy\">The database side of the setup expects the main project tables to already exist, including Users, Books, Authors, BookAuth, Notes, ReadingLog, and NewYorkBS. Once those environment variables and database tables are in place, the pages can run directly from the repo structure.</p>"
puts "                </section>"

puts "                <section id=\"ci-cd\" class=\"about-section\">"
puts "                    <h1>Runner and CI/CD Workflow</h1>"
puts "                    <p class=\"about-copy\">Deployment is defined in the GitHub Actions workflow at .github/workflows/publish.yml. The workflow listens for pushes to the main branch, so the deployment process begins when changes are merged or pushed to main.</p>"
puts "                    <pre class=\"about-code\" data-file=\"publis.yml\"><code>#{CGI.escapeHTML(workflowCode)}</code></pre>"
puts "                    <p class=\"about-copy\">The job runs on a self-hosted (<a href=\"https://docs.github.com/en/actions/concepts/runners/self-hosted-runners\">self-hosted runner</a>) labeled Icarus-prod instead of a standard GitHub-hosted machine. That runner lives on the production host, which means the workflow can update the live site directly through local filesystem access.</p>"
puts "                    <p class=\"about-copy\">During deployment, the runner changes into the deployed checkout at /home/Icarus/public_html/Icarus, fetches origin, checks out main, and hard-resets the server copy to origin/main. In effect, GitHub Actions is being used to trigger a pull-and-publish flow on the production machine, so whatever lands on main becomes the version the runner publishes.</p>"
puts "                </section>"

puts "                <section id=\"sign-in-flow\" class=\"about-section\">"
puts "                    <h1>Sign In and Nav Flow</h1>"
puts "                    <p class=\"about-copy\">The sign-in page accepts a username and password, then calls the authentication helpers in backend/authenication.rb to verify the password against the hashed value stored in the database. If the credentials are valid, the page redirects to the account page by auto-submitting (shown below) a POST form that includes usrName as a hidden field.</p>"
puts "                    <pre class=\"about-code\" data-file=\"signIn.cgi\"><code>#{CGI.escapeHTML(signInFlowCode)}</code></pre>"
puts "                    <p class=\"about-copy\">That usrName value is how the site tracks the current user across pages. When no user is signed in, the nav bar uses ordinary anchor links. When usrName is present, the nav bar switches to POST forms so each navigation action can carry usrName forward as a hidden input.</p>"
puts "                    <pre class=\"about-code\" data-file=\"navbar <li>\"><code>#{CGI.escapeHTML(navBar)}</code></pre>"
puts "                    <p class=\"about-copy\">The same pattern is used in other page-to-page actions such as opening books, authors, the reading log, search, and the account page. Instead of using cookie-based sessions, the project keeps the active username moving through forms and hidden fields.</p>"
puts "                </section>"

puts "                <section id=\"notes\" class=\"about-section\">"
puts "                    <h1>Notes</h1>"
puts "                    <p class=\"about-copy\">Notes are attached to individual books and stored in the Notes table. When a signed-in user opens a book page, frontend/book.cgi uses backend/notes.rb to find the user ID for the current usrName and then loads only the notes that belong to that user and that specific book.</p>"
puts "                    <p class=\"about-copy\">Creating a note happens on the book page itself. The form posts the note text, usrName, and book_id back to book.cgi, which calls createNote to insert the note into the database. The helper prepends the current date to the saved text, so each note is stamped when it is created. This uses the same hidden form and auto submit that sign in uses.</p>"
puts "                    <pre class=\"about-code\" data-file=\"notes form\"><code>#{CGI.escapeHTML(notes)}</code></pre>"
puts "                    <p class=\"about-copy\">Deleting a note uses a similar round-trip. Each note includes a delete form that posts delete_note_id back to the same page, and the code verifies that the note belongs to the current user before removing it. After adding or deleting, the page auto-submits back to itself so the visible note list refreshes immediately.</p>"
puts "                </section>"

puts "                <section id=\"reading-log\" class=\"about-section\">"
puts "                    <h1>Reading Log</h1>"
puts "                    <p class=\"about-copy\">The reading log is connected to both the book page and the dedicated readingLog.cgi page. On a book page, a signed-in user can add the current title to ReadingLog or remove it if it is already there. The code checks for an existing row using the current usr_id and book_id before inserting or deleting.</p>"
puts "                    <pre class=\"about-code\" data-file=\"frontend/book.cgi\"><code>#{CGI.escapeHTML(readingLogBookActionsCode)}</code></pre>"
puts "                    <p class=\"about-copy\">After the add or remove action, book.cgi posts back to itself with the same usrName and book_id. That refresh updates the button state so the interface immediately shows whether the book is currently in the user's reading log.</p>"
puts "                    <p class=\"about-copy\">The main reading log page loads every saved book for the signed-in user and displays them in alphabetical order. It also supports filtering within the user's saved books through a search field and allows direct removal from the log by posting removeFromLog and the selected book_id back to readingLog.cgi.</p>"
puts "                    <pre class=\"about-code\" data-file=\"frontend/readingLog.cgi\"><code>#{CGI.escapeHTML(readingLogPageCode)}</code></pre>"
puts "                </section>"

puts "                <section id=\"search\" class=\"about-section\">"
puts "                    <h1>Search</h1>"
puts "                    <p class=\"about-copy\">Search is implemented in frontend/search.cgi with helper methods in backend/search.rb. The page supports book search and author search, and it keeps both the selected search mode and usrName in hidden fields so the state survives when the user changes modes or opens a result.</p>"
puts "                    <pre class=\"about-code\" data-file=\"frontend/search.cgi\"><code>#{CGI.escapeHTML(searchPageCode)}</code></pre>"
puts "                    <p class=\"about-copy\">For books, the backend queries the Books table with a title LIKE pattern. For authors, it queries the Authors table with a name LIKE pattern. That gives the site substring matching behavior directly through SQL rather than requiring a custom string-search routine in Ruby.</p>"
puts "                    <pre class=\"about-code\" data-file=\"backend/search.rb\"><code>#{CGI.escapeHTML(searchBackendCode)}</code></pre>"
puts "                    <p class=\"about-copy\">In practice, the project relies on the database engine to do the heavy lifting for that string matching. So the search flow is built around SQL LIKE, while the Ruby code handles collecting the query, selecting whether the user wants books or authors, and rendering the matching results on the page.</p>"
puts "                </section>"

puts "                <section id=\"icon\" class=\"about-section\">"
puts "                    <h1>Icon</h1>"
puts "                    <p class=\"about-copy\">The site icon dynamically changes based on the user's color scheme preference. This is implemented using a small JavaScript snippet that updates the favicon when the page loads and whenever the color scheme changes.</p>"
puts "                    <pre class=\"about-code\" data-file=\"frontend/about.cgi\"><code>#{CGI.escapeHTML(icon)}</code></pre>"
puts "                </section>"

puts "                <section id=\"unit-tests\" class=\"about-section\">"
puts "                    <h1>Unit Tests</h1>"
puts "                    <p class=\"about-copy\">The project includes a suite of unit tests to ensure the correctness of the backend logic. These tests cover various scenarios and edge cases, helping to maintain code quality and reliability.</p>"
puts "                    <pre class=\"about-code\" data-file=\"backend/tests.rb\"><code>#{CGI.escapeHTML(unitTestsCode)}</code></pre>"
puts "                </section>"

puts "                <section id=\"our-paper\" class=\"about-section\">"
puts "                    <h1>Paper</h1>"
puts "                    <iframe class=\"about-doc-frame\" src=\"https://docs.google.com/document/d/1aNxy3xsNyGdMSp5sdDC2JnRSPKpAC11t4ImpzOUZrow/preview\" title=\"cannot find paper\"></iframe>"
puts "                </section>"
puts "            </main>"
puts "        </div>"

puts "    </body>"
puts "</html>"