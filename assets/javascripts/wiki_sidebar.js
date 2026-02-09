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

    // Dynamic Height/Top Adjustment
    function updateSidebarMetrics() {
        const topMenu = document.getElementById('top-menu');
        const topHeight = topMenu ? topMenu.offsetHeight : 0;

        // If top menu is sticky (global setting), we need to offset the sidebar
        // We check if body has the sticky class
        const isSticky = document.body.classList.contains('mini-sidebar-sticky-top-menu');

        if (isSticky) {
            sidebar.style.top = topHeight + 'px';
            sidebar.style.height = `calc(100vh - ${topHeight}px)`;
            sidebar.style.maxHeight = `calc(100vh - ${topHeight}px)`;
        } else {
            // If top menu scrolls away, sidebar is sticky to viewport top (0)
            // BUT its height should still not exceed viewport.
            // When scrolled down, top is 0.
            sidebar.style.top = '0px';
            sidebar.style.height = '100vh';
            sidebar.style.maxHeight = '100vh';
        }
    }

    // Run initially and on resize
    updateSidebarMetrics();
    window.addEventListener('resize', updateSidebarMetrics);

    // State Persistence (Expanded Nodes)
    function getLiIdentifier(li) {
        const link = li.querySelector('a');
        return link ? link.getAttribute('href') : null;
    }

    function saveExpandedState() {
        const expandedIds = [];
        sidebar.querySelectorAll('li.expanded').forEach(li => {
            const id = getLiIdentifier(li);
            if (id) expandedIds.push(id);
        });
        localStorage.setItem('redmine_subnavigation_expanded_nodes', JSON.stringify(expandedIds));
    }

    function restoreExpandedState() {
        const stored = localStorage.getItem('redmine_subnavigation_expanded_nodes');
        if (!stored) return;
        try {
            const expandedIds = JSON.parse(stored);
            if (!Array.isArray(expandedIds)) return;

            // Create a Set for faster lookup
            const idSet = new Set(expandedIds);

            sidebar.querySelectorAll('li').forEach(li => {
                const id = getLiIdentifier(li);
                if (id && idSet.has(id)) {
                    li.classList.add('expanded');
                    const ul = li.querySelector('ul');
                    if (ul) ul.style.display = 'block';
                }
            });
        } catch (e) {
            console.error('Failed to restore sidebar state', e);
        }

    }

    // Helper: Scroll to center if out of view
    function scrollToCenterIfNeeded(target) {
        if (!target) return;
        const sidebarContent = sidebar.querySelector('.mini-wiki-sidebar-content');
        if (!sidebarContent) return;

        const targetRect = target.getBoundingClientRect();
        const containerRect = sidebarContent.getBoundingClientRect();

        // Check if out of view (margin 10px)
        const isAbove = targetRect.top < containerRect.top + 10;
        const isBelow = targetRect.bottom > containerRect.bottom - 10;

        if (isAbove || isBelow) {
            target.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    // WRAPPER for Initialization to prevent flickering
    // We disable transitions globally on the sidebar until initial expansion is done
    sidebar.classList.add('no-transition');

    try {
        // Restore state immediately
        restoreExpandedState();

        if (storedWidth && !isClosed) {
            sidebar.style.width = storedWidth + 'px';
            sidebar.style.minWidth = storedWidth + 'px';
        }

        if (isClosed) {
            document.body.classList.add('mini-wiki-sidebar-closed');
        }

        // 3. Resizer (Code remains, appended below)
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

        // 1. Try Exact Match
        for (let link of links) {
            const hrefPath = decodeURIComponent(link.getAttribute('href'));
            if (hrefPath === currentPath) {
                activePageLink = link;
                break;
            }
        }

        // 2. Try Wiki Start Page Match (e.g. /projects/foo/wiki vs /projects/foo/wiki/Wiki)
        if (!activePageLink) {
            // Check if current path ends in /wiki
            // If so, we might need to find the "Wiki" page link or the Project link if it acts as wiki root?
            // Usually the "Wiki" tab links to /wiki, which redirects to /wiki/Wiki or similar.
            // But the sidebar link probably points to /wiki/Wiki directly.

            if (currentPath.endsWith('/wiki')) {
                for (let link of links) {
                    const hrefPath = decodeURIComponent(link.getAttribute('href'));
                    // Check if href is /wiki/Wiki or /wiki/Insex etc.
                    // Best guess: The first page in the list is usually the start page if sorted? 
                    // Or check if href = currentPath + '/Wiki'
                    if (hrefPath === currentPath + '/Wiki' || hrefPath === currentPath + '/index') {
                        activePageLink = link;
                        break;
                    }
                }
            }

            // 3. Reverse Check: Current path is /wiki/Wiki but link is /wiki (rare in sidebar but possible)
            if (!activePageLink && currentPath.endsWith('/Wiki')) {
                const basePath = currentPath.substring(0, currentPath.length - 5); // remove /Wiki
                for (let link of links) {
                    const hrefPath = decodeURIComponent(link.getAttribute('href'));
                    if (hrefPath === basePath) {
                        activePageLink = link;
                        break;
                    }
                }
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
                // Scroll to page link if needed - DISABLED to prevent jumping behavior (user preference: stability)
                // if (!isClosed) {
                //    setTimeout(() => activePageLink.scrollIntoView({ behavior: 'smooth', block: 'center' }), 100);
                // }
            }
        } else {
            // Fallback: If no direct link match (e.g. Issues tab, Settings, etc.)
            // highlight the Project Folder if we are inside a project
            // path format: /projects/:identifier/...
            const pathParts = currentPath.split('/');
            const projectsIndex = pathParts.indexOf('projects');

            if (projectsIndex !== -1 && pathParts.length > projectsIndex + 1) {
                const projectIdentifier = pathParts[projectsIndex + 1];
                // Check if we are in Wiki?
                // If /projects/:id/wiki detected, we usually have a direct link match above.
                // If NOT found above, maybe it's a new page or unlisted? 
                // User says: "if wiki page open, only highlight wiki entry".
                // Since we didn't find a wiki entry match above, maybe we shouldn't highlight project?
                // BUT standard behavior: if in Wiki module, highlight Wiki parent?
                // Let's check tab.

                const isWiki = pathParts.includes('wiki');

                if (!isWiki) {
                    // Find project link matching /projects/:identifier
                    // We look for links that END with /projects/:identifier or match exactly
                    // Note: smart_project_path might point to /activity or /issues
                    // So strict href match might fail if we are on /issues but link is /projects/:id (Overview)
                    // We need to match by Identifier or roughly.

                    const projectLinks = sidebar.querySelectorAll('a.wiki-page-link.type-project');
                    for (let link of projectLinks) {
                        const href = link.getAttribute('href');
                        // Check if href contains the identifier
                        if (href && href.includes(`/projects/${projectIdentifier}`)) {
                            link.classList.add('active');
                            // Expand parents
                            const currentLi = link.closest('li');
                            if (currentLi) {
                                let parent = currentLi;
                                while (parent && parent !== sidebar) {
                                    if (parent.tagName === 'LI') {
                                        parent.classList.add('expanded');
                                        const ul = parent.querySelector('ul');
                                        if (ul) ul.style.display = 'block';
                                    }
                                    parent = parent.parentElement;
                                }
                            }
                            break; // Stop after finding the project
                        }
                    }
                }
            }
        }

        // Save state after auto-expansion to persist active path
        saveExpandedState();

        // 5. Restore Scroll Position
        const savedScrollTop = localStorage.getItem('redmine_subnavigation_scroll_top');
        if (savedScrollTop) {
            sidebar.querySelector('.mini-wiki-sidebar-content').scrollTop = parseInt(savedScrollTop);
        }

        // 6. Conditional Scroll: Logic moved to upper scope (see lines 86+)

        if (activePageLink && !isClosed) {
            // Delay slightly to ensure layout is stable/expanded
            setTimeout(() => scrollToCenterIfNeeded(activePageLink), 100);
        }

        // Save state after auto-expansion to persist active path
        saveExpandedState();

    } finally {
        // Double RAF to ensure repaint before transition restore
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                sidebar.classList.remove('no-transition');
            });
        });
    }

    // 6. Save Scroll Position on Scroll
    const contentDiv = sidebar.querySelector('.mini-wiki-sidebar-content');
    if (contentDiv) {
        // Throttled save
        let scrollTimeout;
        contentDiv.addEventListener('scroll', function () {
            if (scrollTimeout) clearTimeout(scrollTimeout);
            scrollTimeout = setTimeout(function () {
                localStorage.setItem('redmine_subnavigation_scroll_top', contentDiv.scrollTop);
            }, 100);
        });
    }
    // B. Header Navigation Highlighting (Robust)
    function highlightHeader(anchor, clickedLink = null) {
        // Clear previous header/sidebar highlights
        sidebar.querySelectorAll('a.wiki-header-link').forEach(a => a.classList.remove('active'));
        document.querySelectorAll('.wiki-header-highlight-target').forEach(el => el.classList.remove('wiki-header-highlight-target'));

        // 1. Sidebar Active State
        let activeLink = clickedLink;
        if (!activeLink && anchor) {
            // A. Try Exact Attribute Match
            activeLink = sidebar.querySelector(`a.wiki-header-link[data-anchor="${anchor}"]`);

            // B. Fallback: Reverse Slug Match
            // URL might be "My-Header" but Sidebar expects "my-header".
            // OR URL is "My-Header" and Sidebar Text is "My Header".
            if (!activeLink) {
                // specific cleanup for common Redmine/Textile patterns
                // Replace hyphens/underscores with spaces
                const humanizedAnchor = anchor.replace(/[-_]/g, ' ').toLowerCase();

                const links = sidebar.querySelectorAll('a.wiki-header-link');
                for (let link of links) {
                    const text = (link.getAttribute('data-header-text') || '').toLowerCase();
                    // Check if normalized matches
                    if (text && (text === humanizedAnchor || text.includes(humanizedAnchor))) {
                        activeLink = link;
                        break;
                    }
                }
            }
        }
        if (activeLink) {
            activeLink.classList.add('active');
            // Also scroll sidebar if needed (e.g. hash jump)
            if (!sidebar.classList.contains('mini-wiki-sidebar-closed')) {
                scrollToCenterIfNeeded(activeLink);
            }
        }

        // 2. Content Highlight (Target Header)
        if (!anchor && !activeLink) return;

        let target = null;
        // STRATEGY: Find target by multiple means, prioritizing exactness then fuzziness

        // 1. Try Anchor/ID (Case-Insensitive)
        // Redmine anchors might be Mixed-Case ("My-Header") while we have "my-header".
        if (anchor) {
            // A. Exact Name (Textile <a name="...">)
            target = document.querySelector(`a[name="${anchor}"]`);

            // B. Exact ID
            if (!target) target = document.getElementById(anchor);

            // C. Case-Insensitive Name Match
            if (!target) {
                const allAnchors = document.getElementsByTagName('a');
                for (let a of allAnchors) {
                    if (a.name && a.name.toLowerCase() === anchor.toLowerCase()) {
                        target = a;
                        break;
                    }
                }
            }

            // D. Case-Insensitive ID Match (scan all relevant elements)
            if (!target) {
                // Optimization: Only scan wiki content or headers to avoid full DOM scan if possible, 
                // but ID should be unique enough.
                const candidates = document.querySelectorAll('.wiki *[id], .wiki a[name]');
                for (let el of candidates) {
                    const id = el.id || el.getAttribute('name');
                    if (id && id.toLowerCase() === anchor.toLowerCase()) {
                        target = el;
                        break;
                    }
                }
            }
        }

        // 2. Fallback: Search by Text Content (Fuzzy Matching)
        // Only if no target found by ID/Anchor
        if (!target && activeLink) {
            const headerText = activeLink.getAttribute('data-header-text');
            if (headerText) {
                // Normalize function: strip punctuation, lowercase, squish whitespace
                const normalize = (str) => str.replace(/[^\w\s\u00C0-\u017F]/g, '').replace(/\s+/g, ' ').trim().toLowerCase();
                const searchNorm = normalize(headerText);

                const headers = document.querySelectorAll('.wiki h1, .wiki h2, .wiki h3, .wiki h4, .wiki h5');
                for (let h of headers) {
                    // Try exact content first
                    if (h.textContent.trim() === headerText) {
                        target = h;
                        break;
                    }
                    // Try normalized match
                    if (normalize(h.textContent) === searchNorm) {
                        target = h;
                        break;
                    }
                }
            }
        }

        if (target) {
            // If target is <a> (anchor), the visual header is usually the next sibling
            if (target.tagName === 'A') {
                // Sometimes Redmine puts <a> inside the h2 (Markdown) or before (Textile)
                // If <a> is empty and has a next sibling header, target that
                if (target.nextElementSibling && /^H[1-6]$/.test(target.nextElementSibling.tagName)) {
                    target = target.nextElementSibling;
                } else if (target.parentElement && /^H[1-6]$/.test(target.parentElement.tagName)) {
                    target = target.parentElement;
                }
            }

            if (target) {
                target.classList.add('wiki-header-highlight-target');
                // Use scrollIntoView with some margin/offset support if possible, or standard center
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

    // 5. EVENT DELEGATION for Expand/Collapse with Recursive Toggle
    sidebar.addEventListener('click', function (e) {
        // Check if clicked element is expand-icon or inside it
        const icon = e.target.closest('.expand-icon');
        if (icon) {
            e.preventDefault();
            e.stopPropagation();

            const li = icon.closest('li');
            if (li) {
                // Determine action based on current state
                const isExpanding = !li.classList.contains('expanded');

                // Recursive Toggle (Alt/Option Key)
                if (e.altKey) {
                    const allChildLis = li.querySelectorAll('li');
                    allChildLis.forEach(childLi => {
                        // Only toggle if it has children (ul) or an icon
                        if (childLi.querySelector('ul') || childLi.querySelector('.expand-icon')) {
                            const childUl = childLi.querySelector('ul');
                            if (isExpanding) {
                                childLi.classList.add('expanded');
                                if (childUl) childUl.style.display = 'block';
                            } else {
                                childLi.classList.remove('expanded');
                                if (childUl) childUl.style.display = 'none';
                            }
                        }
                    });
                }

                // Toggle current node
                li.classList.toggle('expanded');
                const childrenUl = li.querySelector('ul');
                if (childrenUl) {
                    childrenUl.style.display = li.classList.contains('expanded') ? 'block' : 'none';
                }

                // Save state
                saveExpandedState();
            }
        }
    });

    // Initialize Icons (DOM only - no listeners attached)
    const items = sidebar.querySelectorAll('li');
    items.forEach(li => {
        const isTopLevel = li.parentElement.parentElement.classList.contains('mini-wiki-sidebar-content');
        // Only force expand top level if not explicitly set? 
        // Actually line 350 forces it. Keep it for now.
        if (isTopLevel) {
            li.classList.add('expanded');
        }

        const childrenUl = li.querySelector('ul');
        if (childrenUl) {
            // Icons are now rendered server-side mostly.
            if (!li.querySelector('.expand-icon') && !li.querySelector('.expand-icon-spacer')) {
                // Check if it really has children?

                // If sidebar js runs, maybe structure changed?
                // For now assume Ruby does job. 
                // If not, we might need to inject container? Too complex for fallback.
                // Let's assume Ruby is source of truth.

                // However, we need to handle the case where "expanded" class logic in JS needs to find UL.
            }
        } else {
            // Spacer handled by Ruby?
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

    // 7. Dynamic Theme Style Extraction
    function applyDynamicThemeStyles() {
        let foundRule = null;
        // Search matching rules in all stylesheets
        try {
            for (const sheet of document.styleSheets) {
                try {
                    const rules = sheet.cssRules || sheet.rules;
                    if (!rules) continue;

                    for (const rule of rules) {
                        if (rule.selectorText &&
                            rule.selectorText.includes('#project-jump') &&
                            rule.selectorText.includes('.drdn-items') &&
                            rule.selectorText.includes('a:hover')) {
                            foundRule = rule;
                            break;
                        }
                    }
                } catch (e) {
                    // Access to cross-origin stylesheets might fail
                }
                if (foundRule) break;
            }
        } catch (e) {
            console.warn("[Subnav] Error iterating stylesheets:", e);
        }

        if (foundRule) {
            const bg = foundRule.style.backgroundColor;
            const col = foundRule.style.color;
            const dec = foundRule.style.textDecoration; // e.g. underline

            // We update the CSS variables on :root (html) so they cascade
            if (bg && bg !== '' && bg !== 'initial' && bg !== 'transparent' && bg !== 'rgba(0, 0, 0, 0)') {
                document.documentElement.style.setProperty('--subnav-active-bg', bg);
            }
            if (col && col !== '' && col !== 'initial') {
                document.documentElement.style.setProperty('--subnav-active-text', col);
            }
        } else {
            // Fallback or specific override for standard Redmine (white bg, blue link)
            // if no rule found, we keep default variables from CSS
        }
    }

    // Run extraction
    applyDynamicThemeStyles();
});
