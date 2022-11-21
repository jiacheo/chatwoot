import Vue from 'vue';
import * as types from '../mutation-types';
import ContactAPI from '../../api/contacts';
import ConversationApi from '../../api/conversations';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContactConversation: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  create: async ({ commit }, params) => {
    commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
      isCreating: true,
    });
    const {
      inboxId,
      message,
      contactId,
      sourceId,
      mailSubject,
      assigneeId,
    } = params;
    try {
      // handle messages from contact detail.
      if (message.additionalAttributes) {
        if (message.additionalAttributes.templateParams) {
          message.additionalAttributes.template_params =
            message.additionalAttributes.templateParams;
          delete message.additionalAttributes.templateParams;
        }
        message.additional_attributes = message.additionalAttributes;
        delete message.additionalAttributes;
      }

      if (message.templateParams) {
        message.template_params = message.templateParams;
        delete message.templateParams;
      }

      const { data } = await ConversationApi.create({
        inbox_id: inboxId,
        contact_id: contactId,
        source_id: sourceId,
        additional_attributes: {
          mail_subject: mailSubject,
        },
        message,
        assignee_id: assigneeId,
      });
      commit(types.default.ADD_CONTACT_CONVERSATION, {
        id: contactId,
        data,
      });
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
        isCreating: false,
      });
    }
  },
  get: async ({ commit }, contactId) => {
    commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await ContactAPI.getConversations(contactId);
      commit(types.default.SET_CONTACT_CONVERSATIONS, {
        id: contactId,
        data: response.data.payload,
      });
      commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
};

export const mutations = {
  [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_CONTACT_CONVERSATIONS]: ($state, { id, data }) => {
    Vue.set($state.records, id, data);
  },
  [types.default.ADD_CONTACT_CONVERSATION]: ($state, { id, data }) => {
    const conversations = $state.records[id] || [];
    Vue.set($state.records, id, [...conversations, data]);
  },
  [types.default.DELETE_CONTACT_CONVERSATION]: ($state, id) => {
    Vue.delete($state.records, id);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
