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

    // 4. Highlight current page & Expand Parents
    const currentPath = decodeURIComponent(window.location.pathname);

    // Convert hrefs to decoded path for comparison to handle special chars/spaces
    const links = sidebar.querySelectorAll('a.wiki-page-link');
    let activeLink = null;

    for (let link of links) {
        // Get the path attribute from href (relative or absolute)
        const hrefPath = decodeURIComponent(link.getAttribute('href'));
        if (hrefPath === currentPath) {
            activeLink = link;
            break;
        }
    }

    if (activeLink) {
        activeLink.classList.add('active');

        // Expand the current LI to show subpages (children)
        const currentLi = activeLink.closest('li');
        if (currentLi) {
            currentLi.classList.add('expanded');
            const childUl = currentLi.querySelector('ul');
            if (childUl) childUl.style.display = 'block';

            // Traverse up to expand all parents
            let parent = currentLi.parentElement;
            while (parent && parent !== sidebar) {
                if (parent.tagName === 'LI') {
                    parent.classList.add('expanded');
                    const parentUl = parent.querySelector('ul');
                    if (parentUl) parentUl.style.display = 'block';
                }
                parent = parent.parentElement;
            }
        }

        if (!isClosed) {
            setTimeout(() => {
                activeLink.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }, 100);
        }
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
