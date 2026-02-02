document.addEventListener('DOMContentLoaded', function () {
    const sidebar = document.getElementById('mini-wiki-sidebar');
    if (!sidebar) return;

    // 1. Move sidebar into #wrapper
    const wrapper = document.getElementById('wrapper');
    const header = document.getElementById('header');

    if (wrapper && sidebar.parentElement !== wrapper) {
        if (header && header.parentElement === wrapper) {
            wrapper.insertBefore(sidebar, header);
        } else {
            wrapper.prepend(sidebar);
        }
    }

    // 2. Restore state
    const isClosed = localStorage.getItem('redmine_mini_wiki_sidebar_closed') === 'true';
    const storedWidth = localStorage.getItem('redmine_mini_wiki_sidebar_width');

    if (storedWidth && !isClosed) {
        sidebar.style.width = storedWidth + 'px';
        sidebar.style.minWidth = storedWidth + 'px';
    }

    if (isClosed) {
        document.body.classList.add('mini-wiki-sidebar-closed');
    }

    // 3. Resizer
    const resizer = document.createElement('div');
    resizer.className = 'mini-wiki-sidebar-resizer';
    sidebar.appendChild(resizer);

    let isResizing = false;

    resizer.addEventListener('mousedown', function (e) {
        e.preventDefault();
        isResizing = true;
        resizer.classList.add('resizing');
        sidebar.classList.add('resizing-active');
        document.body.style.cursor = 'col-resize';
        document.body.classList.add('no-select');
    });

    document.addEventListener('mousemove', function (e) {
        if (!isResizing) return;
        const sidebarRect = sidebar.getBoundingClientRect();
        let newWidth = e.clientX - sidebarRect.left;
        if (newWidth < 150) newWidth = 150;
        if (newWidth > 600) newWidth = 600;
        sidebar.style.width = newWidth + 'px';
        sidebar.style.minWidth = newWidth + 'px';
    });

    document.addEventListener('mouseup', function (e) {
        if (!isResizing) return;
        isResizing = false;
        resizer.classList.remove('resizing');
        sidebar.classList.remove('resizing-active');
        document.body.style.cursor = '';
        document.body.classList.remove('no-select');
        if (!document.body.classList.contains('mini-wiki-sidebar-closed')) {
            localStorage.setItem('redmine_mini_wiki_sidebar_width', parseInt(sidebar.style.width));
        }
    });

    // 4. Highlight Logic

    // A. Highlight Current Page Node & Expand Tree
    const currentPath = decodeURIComponent(window.location.pathname);
    const links = sidebar.querySelectorAll('a.wiki-page-link');
    let activePageLink = null;

    for (let link of links) {
        const hrefPath = decodeURIComponent(link.getAttribute('href'));
        if (hrefPath === currentPath) {
            activePageLink = link;
            break;
        }
    }

    if (activePageLink) {
        activePageLink.classList.add('active');
        const currentLi = activePageLink.closest('li');
        if (currentLi) {
            // Expand parents
            let parent = currentLi;
            while (parent && parent !== sidebar) {
                if (parent.tagName === 'LI') {
                    parent.classList.add('expanded');
                    const ul = parent.querySelector('ul');
                    if (ul) ul.style.display = 'block';
                }
                parent = parent.parentElement;
            }
            // Scroll to page link if needed
            if (!isClosed) {
                setTimeout(() => activePageLink.scrollIntoView({ behavior: 'smooth', block: 'center' }), 100);
            }
        }
    }

    // B. Header Navigation Highlighting (Robust)
    function highlightHeader(anchor, clickedLink = null) {
        // Clear previous header/sidebar highlights
        sidebar.querySelectorAll('a.wiki-header-link').forEach(a => a.classList.remove('active'));
        document.querySelectorAll('.wiki-header-highlight-target').forEach(el => el.classList.remove('wiki-header-highlight-target'));

        // 1. Sidebar Active State
        let activeLink = clickedLink;
        if (!activeLink && anchor) {
            // Case-insensitive attribute match for robustness
            activeLink = sidebar.querySelector(`a.wiki-header-link[data-anchor="${anchor}"]`);
        }
        if (activeLink) activeLink.classList.add('active');

        // 2. Content Highlight (Target Header)
        if (!anchor && !activeLink) return;

        let target = null;

        // Try exact ID match first
        if (anchor) target = document.getElementById(anchor);

        // Try named anchor <a name="foo"> which Redmine uses often
        if (!target && anchor) target = document.querySelector(`a[name="${anchor}"]`);

        // Robust Fallback: Search by Text Content if we know it (from data-header-text)
        if (!target && activeLink) {
            const headerText = activeLink.getAttribute('data-header-text');
            if (headerText) {
                const headers = document.querySelectorAll('.wiki h1, .wiki h2, .wiki h3, .wiki h4, .wiki h5');
                for (let h of headers) {
                    if (h.textContent.trim() === headerText) {
                        target = h;
                        break;
                    }
                }
            }
        }

        if (target) {
            // If target is <a> (anchor), the visual header is usually the next sibling
            if (target.tagName === 'A') target = target.nextElementSibling;

            if (target && /^H[1-6]$/.test(target.tagName)) {
                target.classList.add('wiki-header-highlight-target');
                target.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        }
    }

    // Listener for Header Links
    sidebar.addEventListener('click', function (e) {
        const link = e.target.closest('a.wiki-header-link');
        if (link) {
            const anchor = link.getAttribute('data-anchor');
            highlightHeader(anchor, link);
        }
    });

    // Initial Hash Check
    if (window.location.hash) {
        try {
            const anchor = decodeURIComponent(window.location.hash.substring(1));
            highlightHeader(anchor);
        } catch (e) { console.error(e); }
    }

    // 5. EVENT DELEGATION for Expand/Collapse (Performance Optimization)
    // Instead of attaching listener to every icon, we listen on the sidebar
    sidebar.addEventListener('click', function (e) {
        // Check if clicked element is expand-icon or inside it
        const icon = e.target.closest('.expand-icon');
        if (icon) {
            e.preventDefault();
            e.stopPropagation();

            const li = icon.closest('li');
            if (li) {
                li.classList.toggle('expanded');
                // Toggle display of UL (logic moved from multiple listeners to here)
                const childrenUl = li.querySelector('ul');
                if (childrenUl) {
                    childrenUl.style.display = li.classList.contains('expanded') ? 'block' : 'none';
                }
            }
        }
    });

    // Initialize Icons (DOM only - no listeners attached)
    const items = sidebar.querySelectorAll('li');
    items.forEach(li => {
        const isTopLevel = li.parentElement.parentElement.classList.contains('mini-wiki-sidebar-content');
        if (isTopLevel) {
            li.classList.add('expanded');
        }

        const childrenUl = li.querySelector('ul');
        if (childrenUl) {
            if (isTopLevel) childrenUl.style.display = 'block';

            const toggle = document.createElement('span');
            toggle.className = 'expand-icon';
            // NO onclick handler here anymore!
            li.insertBefore(toggle, li.firstChild);
        } else {
            const spacer = document.createElement('span');
            spacer.style.display = 'inline-block';
            spacer.style.width = '24px'; // Match icon width
            li.insertBefore(spacer, li.firstChild);
        }
    });

    // 6. Global Toggle Function
    window.toggleWikiSidebar = function () {
        document.body.classList.toggle('mini-wiki-sidebar-closed');
        const isNowClosed = document.body.classList.contains('mini-wiki-sidebar-closed');
        localStorage.setItem('redmine_mini_wiki_sidebar_closed', isNowClosed);

        if (!isNowClosed) {
            const stored = localStorage.getItem('redmine_mini_wiki_sidebar_width');
            if (stored) {
                sidebar.style.width = stored + 'px';
                sidebar.style.minWidth = stored + 'px';
            } else {
                sidebar.style.width = '280px';
                sidebar.style.minWidth = '280px';
            }
        }
    }
});
