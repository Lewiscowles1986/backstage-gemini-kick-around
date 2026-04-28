import { createApp } from '@backstage/frontend-defaults';
import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { SignInPageBlueprint } from '@backstage/plugin-app-react';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import scaffolderPlugin from '@backstage/plugin-scaffolder/alpha';
import techdocsPlugin from '@backstage/plugin-techdocs/alpha';
import searchPlugin from '@backstage/plugin-search/alpha';
import notificationsPlugin from '@backstage/plugin-notifications/alpha';
import userSettingsPlugin from '@backstage/plugin-user-settings/alpha';
import authPlugin from '@backstage/plugin-auth';
import { navModule } from './modules/nav';
import { SignInPage } from '@backstage/core-components';

const signInModule = createFrontendModule({
  pluginId: 'app',
  extensions: [
    SignInPageBlueprint.make({
      params: {
        loader: async () => props => (
          <SignInPage
            {...props}
            providers={['guest']}
            title="Select a sign-in method"
          />
        ),
      },
    }),
  ],
});

export default createApp({
  features: [
    catalogPlugin,
    scaffolderPlugin,
    techdocsPlugin,
    searchPlugin,
    notificationsPlugin,
    userSettingsPlugin,
    authPlugin,
    navModule,
    signInModule,
  ],
});
