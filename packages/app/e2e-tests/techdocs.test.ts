import { test, expect } from '@playwright/test';

test('TechDocs should load for repo-a without console errors', async ({ page }) => {
  const consoleErrors: string[] = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
    }
  });

  page.on('requestfailed', request => {
    consoleErrors.push(`Request failed: ${request.url()} (${request.failure()?.errorText})`);
  });

  page.on('response', response => {
    if (response.status() >= 400) {
      consoleErrors.push(`Status ${response.status()} for ${response.url()}`);
    }
  });

  // Navigate to repo-a TechDocs
  await page.goto('/docs/default/component/repo-a');

  // Wait for the content to render
  await expect(page.getByText('Repo A Documentation')).toBeVisible();

  // Check for the kroki diagram
  const krokiImage = page.locator('img[src*="kroki-generated"]');
  // Or if embedded:
  const embeddedKroki = page.locator('svg[id^="kroki-"]');
  
  await expect(krokiImage.or(embeddedKroki).first()).toBeVisible();

  // Verify no console errors occurred during load
  expect(consoleErrors).toEqual([]);
});
